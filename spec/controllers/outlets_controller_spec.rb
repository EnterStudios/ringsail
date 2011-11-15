require 'spec_helper'

describe OutletsController do
  render_views

  describe "GET 'add'" do
    it "should be successful" do
      get :add
      response.should be_success
    end
    
    it "should ask for a service_url if one was not given" do
      get :add
      response.should have_selector("p", :content => "type the full URL")
      response.should have_selector("input", :type => "submit", :value => "Look Up")
    end
    
    describe "with a service_url" do
      it "should display the full form with service_url filled in" do
        Service.create!(:name => "Twitter", :shortname => "twitter")
        service_url = 'http://twitter.com/somethingorother'
        get :add, :service_url => service_url
        response.should have_selector("p", :content => "Update registry information")
        response.should have_selector("a", :href => service_url)
      end
    end
  end

  describe "POST 'update'" do
    
    describe "failure" do

      before(:each) do
        @attr = {
          :service_url => "",
          :organization => "",
          :info_url => "",
          :language => ""
        }
      end
      
      it "should not add an outlet" do
        lambda do
          post :update, :service_url => @attr[:service_url]
        end.should_not change(Outlet, :count)
      end
    end
    
    describe "success" do
      before(:each) do
        Service.create!(:name => "Twitter", :shortname => "Twitter")
        @attr = {
          :service_url => "http://twitter.com/example",
          :organization => "Example Project",
          :info_url => "http://example.gov",
          :language => "English"
        }
      end
      
      it "should add an outlet" do
        lambda do
          post :update, @attr
        end.should change(Outlet, :count).by(1)
      end
      
      it "should set the outlet's attributes" do
        post :update, @attr
        new_outlet = Outlet.find_by_service_url(@attr[:service_url])
        new_outlet.service_url.should  == @attr[:service_url]
        new_outlet.organization.should  == @attr[:organization]
        new_outlet.service.should_not be_nil
      end
      
    end
    
  end

  describe "GET 'verify'" do
  
    describe "for an unverified outlet" do
    
      before(:each) do
        Service.create!(:name => "Twitter", :shortname => "twitter")
      end
    
      it "should be successful" do
        get :verify
        response.should be_success
      end
      
      it "should return an unverified indication" do
        unverified_url = "http://twitter.com/unverified"
        get :verify, :service_url => unverified_url
        response.should have_selector("p", :content => "is not registered")
        response.should have_selector("a", :href => unverified_url)
      end
      
      it "should return no outlet attributes" do
        unverified_url = "http://twitter.com/unverified"
        get :verify, :service_url => unverified_url
        response.should_not have_selector("p", :content => "Organization:")
      end
    end
    
    describe "for a verified outlet" do
      before(:each) do
        # FIXME: Get thee to a factory
        Service.create!(:name => "Twitter", :shortname => "Twitter")
        @verified_url = "http://twitter.com/deptofexample"
        @outlet = Outlet.resolve(@verified_url)
        @outlet.language = 'English';
        @outlet.organization = 'Example Campaign'
        @agency = Agency.create!(:name => "Department of Examples", :shortname => "example")
        @outlet.agencies.push @agency
        @outlet.save!
      end
      
      it "should be successful" do
        get :verify, :service_url => @verified_url
        response.should be_success
      end
      
      it "should return a verified indication" do
        get :verify, :service_url => @verified_url
        response.should have_selector("p", :content => "is registered")
      end
      
      it "should return the attributes of the outlet" do
        get :verify, :service_url => @verified_url
        response.should have_selector("p", :content => "is registered")
        response.should have_selector("p", :content => @outlet.organization)
        response.should have_selector("p", :content => @outlet.language)
      end
    end
  end

  describe "DELETE 'destroy'" do
  
    before(:each) do
      # FIXME: Get thee to a factory
      Service.create!(:name => "Twitter", :shortname => "Twitter")
      @verified_url = "http://twitter.com/deptofexample"
      @outlet = Outlet.resolve(@verified_url)
      @outlet.language = 'English';
      @outlet.organization = 'Example Campaign'
      @agency = Agency.create!(:name => "Department of Examples", :shortname => "example")
      @outlet.agencies.push @agency
      @outlet.save!
    end
    
    describe "as an authorized user" do

       it "should destroy the outlet" do
        lambda do
         delete :destroy, :service => @outlet.service.shortname, :account => @outlet.account
        end.should change(Outlet, :count).by(-1)
      end

      it "should redirect to the add page" do
        delete :destroy, :service => @outlet.service.shortname, :account => @outlet.account
        response.should redirect_to(add_path)
      end
    end
  end

  describe "POST 'remove'" do
  
    before(:each) do
      # FIXME: Get thee to a factory
      Service.create!(:name => "Twitter", :shortname => "Twitter")
      @verified_url = "http://twitter.com/deptofexample"
      @outlet = Outlet.resolve(@verified_url)
      @outlet.language = 'English';
      @outlet.organization = 'Example Campaign'
      @agency = Agency.create!(:name => "Department of Examples", :shortname => "example")
      @outlet.agencies.push @agency
      @outlet.save!
    end
    
    describe "as an authorized user" do

       it "should destroy the outlet" do
        lambda do
          post :remove, :service_url => @outlet.service_url
        end.should change(Outlet, :count).by(-1)
      end

      it "should redirect to the add page" do
        post :remove, :service_url => @outlet.service_url
        response.should redirect_to(add_path)
      end
    end
  end

end
