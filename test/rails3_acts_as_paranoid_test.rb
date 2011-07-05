require 'test_helper'

class ParanoidTest < Test::Unit::TestCase
  #fixtures :Posts


  def setup

    Post.delete_all!
    ["paranoid", "really paranoid", "extremely paranoid"].each do |name|
      Post.create! :name => name, :exclusion_cd => 'IN'
    end
  end

  def test_exclusion_cd
    assert_equal 3, Post.all.count
  end

  def test_only_deleted
    Post.all.first.destroy
    assert_equal 1, Post.only_deleted.count
  end

  def test_with_deleted
    assert_equal 3, Post.count
    assert_equal 3, Post.with_deleted.count
  end

  def test_should_delete
      assert_equal 3, Post.count
      Post.all.first.delete
      assert_equal 2, Post.count
      assert_equal 3, Post.with_deleted.count
  end

  def test_should_destroy
      assert_equal 3, Post.count
      Post.all.first.destroy!
      assert_equal 2, Post.count
      assert_equal 2, Post.with_deleted.count
  end

  def test_should_recover
      assert_equal 3, Post.count
      Post.all.first.delete
      assert_equal 2, Post.count
      Post.only_deleted.first.recover
      assert_equal 3, Post.count
  end

  def test_should_delete_all
      assert_equal 3, Post.count
      Post.delete_all
      assert_equal 0, Post.count
      assert_equal 3, Post.with_deleted.count
      Post.only_deleted.first.recover
      assert_equal 1, Post.count
    end

  def test_should_destroy_all
      assert_equal 3, Post.count
      Post.delete_all!
      assert_equal 0, Post.with_deleted.count
      assert_equal 0, Post.count

  end


end

class Array
  def ids
    collect &:id
  end
end