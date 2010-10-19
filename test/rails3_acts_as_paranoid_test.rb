require 'test_helper'

#["paranoid", "really paranoid", "extremely paranoid"].each do |name|
#  Parent.create! :name => name
#  Son.create! :name => name
#end
#Parent.first.destroy
#Son.delete_all("name = 'paranoid' OR name = 'really paranoid'")
#Parent.count
#Son.count
#Parent.only_deleted.count 
#Son.only_deleted.count
#Parent.with_deleted.count
#Son.with_deleted.count

class ParanoidTest < ActiveSupport::TestCase

  def setup
    setup_db
    
    ["paranoid", "really paranoid", "extremely paranoid"].each do |name|
      ParanoidTime.create! :name => name
      ParanoidBoolean.create! :name => name
    end

    NotParanoid.create! :name => "no paranoid goals"
  end

  def teardown
    teardown_db
  end

  def assert_exception(exception)
    begin
      begin
        yield
      rescue exception
        true
      end
    rescue
      false
    end
  end

  def test_fake_removal
    assert_equal 3, ParanoidTime.count
    assert_equal 3, ParanoidBoolean.count

    ParanoidTime.first.destroy
    ParanoidBoolean.delete_all("name = 'paranoid' OR name = 'really paranoid'")
    assert_equal 2, ParanoidTime.count
    assert_equal 1, ParanoidBoolean.count
    assert_equal 1, ParanoidTime.only_deleted.count 
    assert_equal 2, ParanoidBoolean.only_deleted.count
    assert_equal 3, ParanoidTime.with_deleted.count
    assert_equal 3, ParanoidBoolean.with_deleted.count
  end

  def test_real_removal
    ParanoidTime.first.destroy!
    ParanoidBoolean.delete_all!("name = 'extremely paranoid' OR name = 'really paranoid'")
    assert_equal 2, ParanoidTime.count
    assert_equal 1, ParanoidBoolean.count
    assert_equal 2, ParanoidTime.with_deleted.count
    assert_equal 1, ParanoidBoolean.with_deleted.count
    assert_equal 0, ParanoidBoolean.only_deleted.count
    assert_equal 0, ParanoidTime.only_deleted.count

    ParanoidTime.first.destroy
    ParanoidTime.only_deleted.first.destroy
    assert_equal 0, ParanoidTime.only_deleted.count

    ParanoidTime.delete_all!
    assert_equal [], ParanoidTime.all
    assert_equal [], ParanoidTime.with_deleted.all    
  end

  def test_paranoid_scope
    assert_exception(NoMethodError) { NotParanoid.delete_all! }
    assert_exception(NoMethodError) { NotParanoid.first.destroy! }
    assert_exception(NoMethodError) { NotParanoid.with_deleted }
    assert_exception(NoMethodError) { NotParanoid.only_deleted }    
  end

  def test_recovery
    assert_equal 3, ParanoidBoolean.count
    ParanoidBoolean.first.destroy
    assert_equal 2, ParanoidBoolean.count
    ParanoidBoolean.only_deleted.first.recover
    assert_equal 3, ParanoidBoolean.count
  end
  
  def test_associations_finders
    paranoic_company = Company.create!
    
    assert [], paranoic_company.paranoid_products
    
    pp1 = ParanoidProduct.create(:company => paranoic_company)
    assert_equal [pp1], paranoic_company.paranoid_products
    
    pp2 = ParanoidProduct.create(:company => paranoic_company, :deleted_at => Time.now)
    assert_equal [pp1], paranoic_company.reload.paranoid_products
    
    assert_equal [pp2], paranoic_company.paranoid_products.reload.only_deleted
    
    pp2 = ParanoidProduct.create(:company_id => (paranoic_company.id + 1), :deleted_at => Time.now)
    assert_equal [pp2], paranoic_company.paranoid_products.reload.only_deleted
    # 
    # assert 1, paranoic_company.paranoid_products.count
    # assert 2, ParanoidProduct.count
  end
end
