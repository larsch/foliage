require 'ruby_parser'
require 'ruby2ruby'

# Foliage is branch coverage analyser. It uses ruby_parser and
# Ruby2Ruby to instrument your code and analyse decision/condition
# coverage while running it.
#
# The following code path branches are checked by Foliage:
#
#   if, unless
#   while, until
#   &&, ||, and, or
#
# Foilage does not check branching at method calls. For example
# 'obj.method' may invoke different methods depending on the type of
# 'obj'.
module Foliage
  VERSION = '1.0.0'

  BranchTable = []

  # Collection of methods to be included into the Sexp class.
  module SexpDeepDup
    # Performs a deep copy on Sexp objects. This is needed because
    # Ruby2Ruby#process will modify its arguments (insert explicitive
    # here).
    def deep_dup
      s = Sexp.new(*map { |p| p.respond_to?(:deep_dup) ? p.deep_dup : p })
      s.line = self.line
      s.file = self.file
      s
    end
  end

  # Hook is the base class for instrumentation hooks. The Hook object
  # will be looked up at the instrumentation point and its #hook
  # method will be called.
  class Hook
    def initialize(sexp)
      @sexp = sexp
    end

    def expr
      @expr ||= Ruby2Ruby.new.process(@sexp)
    end

    def line
      @sexp.line
    end

    def file
      @sexp.file
    end

    # The hook method is called at the instrumentation point and
    # must return its argument.
    def hook(val)
      raise NotImplementedError
    end

    # Construct a Sexp which calls Hook#hook on this object (in the
    # current Ruby interpreter instance only).
    def sexp
      s(:call,
        s(:call,
          s(:const, "ObjectSpace"),
          :_id2ref,
          s(:arglist, s(:lit, object_id))),
        :hook,
        s(:arglist, @sexp.deep_dup))
    end
  end

  # ConditionHook's are inserted at standard branch points (if, unless,
  # while, until, and, or, &&, ||). ConditionHook checks that the
  # condition is tested while both true and false.
  class ConditionHook < Hook
    attr_accessor :true_tested
    attr_accessor :false_tested

    def initialize(*args)
      super(*args)
      @true_tested = false
      @false_tested = false
    end

    def hook(val)
      if val
        @true_tested = true
      else
        @false_tested = true
      end
      return val
    end

    def report
      reports = []
      if !@true_tested
        reports.push "#{file}:#{line}: Branch condition #{expr} was never true."
      end
      if !@false_tested
        reports.push "#{file}:#{line}: Branch condition #{expr} was never false."
      end
      return reports
    end
  end

  # CaseHook's are instead when a case operand is matched with 'when'
  # parameters. The CaseHook only checks that each match happens at
  # least once.
  class CaseHook < Hook
    attr_accessor :match

    def initialize(*args)
      super(*args)
      @match = false
    end

    def hook(val)
      @match = true if val
      return val
    end

    def report
      reports = []
      if !@match
        reports.push "#{file}:#{line}: case operand never matched #{expr}."
      end
      return reports
    end
  end

  # CaseElseHook's are insert when the 'else' part of a case statement
  # to check that case operand is tested when not matching any of the
  # 'when' parameters.
  class CaseElseHook < Hook
    attr_accessor :nomatch

    def initialize(*args)
      super(*args)
      @nomatch = false
    end
    
    def hook(val)
      @nomatch = true
      return val
    end

    def report
      reports = []
      if !@nomatch
        reports.push "case operand never matched nothing."
      end
      return reports
    end
  end
  
  def self.instrument_branch(sexp, in_condition)
    sexp[1] = instrument_cond(sexp[1], true)
    sexp[2] = instrument(sexp[2], in_condition)
    sexp[3] = instrument(sexp[3], in_condition)
  end

  def self.instrument_cond(sexp, in_condition)
    isexp = instrument(sexp, in_condition)
    branch = ConditionHook.new(isexp)
    BranchTable.last.push(branch)
    return branch.sexp
  end

  def self.instrument_case(sexp, in_condition)
    new = nil
    operand = sexp[1]

    elseexpr = sexp[-1] || s(:nil)

    elseexpr = instrument(elseexpr, in_condition)
    
    hook = CaseElseHook.new(elseexpr)
    elseexpr = hook.sexp
    BranchTable.last.push(hook)

    nextif = elseexpr
    
    sexp[2..-2].reverse.each do |subsexp|
      orsexp = nil
      subsexp[1][1..-1].reverse.each do |value|
        test = s(:call, value, :===, operand.deep_dup)
        hook = CaseHook.new(test)
        inst = hook.sexp
        BranchTable.last.push(hook)
        if orsexp
          orsexp = s(:or, inst, orsexp)
        else
          orsexp = inst
        end
      end
      nextif = s(:if, orsexp, subsexp[-1], nextif)
    end

    sexp.replace(nextif)
  end

  # Recursively instruments an Sexp instance.
  #
  # == Parameters:
  #
  # +sexp+:: The Sexp object to instrument.
  #
  # +in_condition+:: Boolean set to true if the current Sexp may cause
  # branching.
  def self.instrument(sexp, in_condition = nil)
    case sexp
    when Sexp
      case sexp.node_type
      when :if, :while, :until
        instrument_branch(sexp, in_condition)
      when :case
        instrument_case(sexp, in_condition)
      when :and, :or
        sexp[1] = instrument_cond(sexp[1], true)
        if in_condition
          sexp[2] = instrument_cond(sexp[2], in_condition)
        end
      else
        sexp.each do |y|
          instrument(y, in_condition)
        end
      end
    end
    
    return sexp
  end

  def self.cov_text(text, file = '-')
    BranchTable.push([])
    sexp = RubyParser.new.parse(text, file)
    if sexp
      instrumented_sexp = instrument(sexp)
      instrumented_code = Ruby2Ruby.new.process(instrumented_sexp)
      eval instrumented_code, binding, file
    end
    report(BranchTable.pop)
  end
  
  def self.cov_file(filename)
    cov_text(File.read(filename), filename)
  end

  def self.report(hooks)
    report_lines = []
    hooks.each do |hook|
      report_lines.concat(hook.report)
    end
    return report_lines
  end

  def self.cov
    BranchTable.push([])
    yield
    report(BranchTable.pop)
  end

end

class Sexp #:nodoc:
  include Foliage::SexpDeepDup
end
