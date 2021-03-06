require 'spec_helper'

describe Organisation do
  before(:each) do
    @organisation = Organisation.make(:name => 'abc', :subdomain => 'fromage')
    Setting[:base_domain] = 'oneclickorgs.com'
  end
  
  describe "validation" do
    it "should not allow multiple organisations with the same subdomain" do
      @first = Organisation.make(:name => 'abc', :subdomain => "apples")

      lambda do
        @second = Organisation.make(:name => 'def', :subdomain => "apples")
      end.should raise_error(ActiveRecord::RecordInvalid)
    end
  end
  
  describe "text fields" do
    before(:each) do
      @organisation.name = 'The Cheese Collective' # actually stored as 'organisation_name'
      @organisation.save!
      @organisation.reload
    end
    
    it "should get the name of the organisation" do
      @organisation.name.should == ("The Cheese Collective")
    end

    it "should change the name of the organisation" do
      lambda {
        @organisation.name = "The Yoghurt Yurt"
        @organisation.save!
        @organisation.reload
      }.should change(Clause, :count).by(1)
      @organisation.name.should == "The Yoghurt Yurt"
    end
  end
  
  describe "domain" do
    it "should return the root URL for this organisation" do
      @organisation.domain.should == "http://fromage.oneclickorgs.com"
    end
    
    context "with only_host option true" do
      it "should remove the http://" do
        @organisation.domain(:only_host => true).should == "fromage.oneclickorgs.com"
      end
    end
    
    context "in single-organisation mode" do
      before(:each) do
        Setting[:single_organisation_mode] = "true"
      end
      
      it "returns the base domain" do
        @organisation.domain.should == "http://oneclickorgs.com"
      end
    end
  end
  
end
