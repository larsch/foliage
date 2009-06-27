require 'test/unit'
require 'foliage'

class FoliageTest < Test::Unit::TestCase
  
  def test_empty
    report = Foliage.cov_text("")
  end

  def test_iftrue
    report = Foliage.cov_text("if true; 1; end")
    assert_equal 1, report.size
    assert_match(/condition true was never false/, report[0])
  end

  # Short circuiting operators (&& and ||) can cause code
  # branching. Test that the first operand is checked for all possible
  # outcomes.
  def test_short_circuit
    report = Foliage.cov_text("true && 0")
    assert_equal 1, report.size
    assert_match(/condition true was never false/, report[0])
    
    report = Foliage.cov_text("false || 0")
    assert_equal 1, report.size
    assert_match(/condition false was never true/, report[0])

    # All sub-expressions of the first operand of a short-circuiting
    # operator can cause code branches. Check that this is reported.
    report = Foliage.cov_text("[true,false].each do |b| (b && true) && 0; end")
    assert_equal 1, report.size
    assert_match(/condition true was never false/, report[0])
  end
  
  def test_subiftrue
    report = Foliage.cov_text("[true,false].each do |x| if x; 1; true && false; end; end")
    assert_equal 1, report.size
    assert_match(/condition true was never false/, report[0])
  end

  def test_iffalse
    report = Foliage.cov_text("if false; 1; end")
    assert_equal 1, report.size
    assert_match(/condition false was never true/, report[0])
  end

  def test_gt_true
    report = Foliage.cov_text("a=2;if a > 0; 1; end")
    assert_equal 1, report.size
    assert_match(/condition \(a > 0\) was never false/, report[0])
  end

  def test_gt_false
    report = Foliage.cov_text("a=2;if a > 4; 1; end")
    assert_equal 1, report.size
    assert_match(/condition \(a > 4\) was never true/, report[0])
  end

  def test_and
    report = Foliage.cov_text %{ [true,false].each{|x| (x and true) ? 1 : 2 } }
    assert_equal 1, report.size
    assert_match(/condition true was never false/, report[0])
  end

  def test_or
    report = Foliage.cov_text %{ [true,false].each{|x| (x or false) ? 1 : 2 } }
    assert_equal 1, report.size
    assert_match(/condition false was never true/, report[0])
  end

  def test_ampamp
    report = Foliage.cov_text %{ [true,false].each{|x| (x && true) ? 1 : 2 } }
    assert_equal 1, report.size
    assert_match(/condition true was never false/, report[0])
  end
  
  def test_barbar
    report = Foliage.cov_text %{ [true,false].each{|x| (x || false) ? 1 : 2 } }
    assert_equal 1, report.size
    assert_match(/condition false was never true/, report[0])
  end

  def test_case_ok
    report = Foliage.cov_text %{ [1,2,3].each { |x| case x; when 1, 2; 2; end } }
    assert_equal(0, report.size)
  end
  
  def test_case
    report = Foliage.cov_text %{ [1, 2].each { |x| case x; when 1, 3; 2; end } }
    assert_equal 1, report.size
    assert_match(/case operand never matched 3/, report[0])
  end

  def test_caseelse
    report = Foliage.cov_text %{ [1, 2].each { |x| case x; when 1, 2; 3; else 4 end } }
    assert_equal 1, report.size
    assert_match(/case operand never matched nothing/, report[0])
  end

  def test_caseelsenoelse
    report = Foliage.cov_text %{ [1, 2].each { |x| case x; when 1, 2; 3; end } }
    assert_equal 1, report.size
    assert_match(/case operand never matched nothing/, report[0])
  end

  def test_condincaseelse
    report = Foliage.cov_text %{ [1,2,3].each { |x| case x; when 1, 2; 2; else true && false end } }
    assert_equal(1, report.size)
    assert_match(/condition true was never false/, report[0])
  end

  def test_until
    report = Foliage.cov_text %{ until true; raise; end }
    assert_equal(1, report.size)
    assert_match(/condition true was never false/, report[0])
    
    report = Foliage.cov_text %{ until false; break; end }
    assert_equal(1, report.size)
    assert_match(/condition false was never true/, report[0])

    report = Foliage.cov_text %{ x = false; until x; x = true; end }
    assert_equal(0, report.size)
  end

  def test_while
    report = Foliage.cov_text %{ while false; raise; end }
    assert_equal(1, report.size)
    assert_match(/condition false was never true/, report[0])
    
    report = Foliage.cov_text %{ while true; break; end }
    assert_equal(1, report.size)
    assert_match(/condition true was never false/, report[0])

    report = Foliage.cov_text %{ x = true; while x; x = false; end }
    assert_equal(0, report.size)
  end

  def test_unless
    report = Foliage.cov_text %{ 1 unless true }
    assert_equal(1, report.size)
    assert_match(/condition true was never false/, report[0])
    
    report = Foliage.cov_text %{ 1 unless false }
    assert_equal(1, report.size)
    assert_match(/condition false was never true/, report[0])

    report = Foliage.cov_text %{ [true,false].each do |b| 1 unless b; end }
    assert_equal(0, report.size)
  end

  def test_line_numbers
    report = Foliage.cov_text %{ 1 unless true }
    assert_match(/^-:1:/, report[0])
    
    report = Foliage.cov_text %{ \n 1 unless true }
    assert_match(/^-:2:/, report[0])

    #ruby_parser bug with line_numbers
    # report = Foliage.cov_text %{ \n 1 unless true \n \n }
    # assert_match(/^-:2:/, report[0])
  end
  
end
