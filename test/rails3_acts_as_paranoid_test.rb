require 'test_helper'

class ParanoidTest < Test::Unit::TestCase
  fixtures :Blog

  def test_should_recognize_with_exclusion_cd
    assert_equal [2, 4], Blog.find(:all, :conditions => ["exclusion_cd = 'IN'"]).collect { |w| w.id }
    assert_equal [1, 3], Blog.find(:all, :conditions => ["exclusion_cd = 'OUT'"]).collect { |w| w.id }
  end

  def test_should_recognize_with_only_deleted
    assert_equal [1, 3], Blog.only_deleted.collect { |w| w.id }
  end

  def test_is_deleted
    assert_equal false, Blog.is_deleted?(2)
    assert_equal true, Blog.is_deleted?(3)
  end

  def test_should_count_with_deleted
    assert_equal 2, Blog.count
    assert_equal 4, Blog.count_with_deleted
    assert_equal 2, Blog.count_only_deleted
  end

  def test_should_set_deleted_at
    assert_equal 1, Blog.count
    Blog(:blog_1).destroy
    assert_equal 0, Blog.count
    assert_equal 2, Blog.calculate_with_deleted(:count, :all)
  end

  def test_should_destroy
    assert_equal 2, Blog.count
    Blog(:blog_1).destroy!
    assert_equal 1, Blog.count
    assert_equal 3, Blog.count_only_deleted
    assert_equal 4, Blog.cont_with_deleted
  end
end

class Array
  def ids
    collect &:id
  end
end