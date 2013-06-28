# Users Model Spec
require 'support/database/connection'
require 'cf_control_panel/models'

include CFControlPanel::Models

describe User do

  # clear the database of users before each test
  before :each do
    User.delete
  end

  describe "create" do

    describe "with one record" do

      before :each do
        User.unrestrict_primary_key
        @user = User.create(:id => 'abc_12345', :email => 'user@domain.com')
      end
      
      it "should return the created record" do
        User.first.should == @user
      end

    end

  end

  describe "validations" do
    
    before :each do
      User.unrestrict_primary_key
    end

    it "should require an email address" do
      User.new().should_not be_valid
      User.new(:id => 'abc_12345', :email => '').should_not be_valid
      User.new(:id => 'abc_12345', :email => "user@domain.com").should be_valid
    end

    it "should validate an email address" do
      User.new(:id => 'abc_12345', :email => 'arbitrary text').should_not be_valid
      User.new(:id => 'abc_12345', :email => "user@domain.com").should be_valid
    end

    describe "with unique validations" do

      before :each do
        @user = User.create(:id => 'abc_12345', :email => 'user@domain.com')
      end

      it "should ensure an id is unique" do
        User.new(:id => 'abc_12345', :email => 'user2@domain.com').should_not be_valid
        User.new(:id => 'def_12345', :email => 'user2@domain.com').should be_valid
      end

      it "should ensure an email is unique" do
        User.new(:id => 'def_12345', :email => 'user@domain.com').should_not be_valid
        User.new(:id => 'def_12345', :email => 'user2@domain.com').should be_valid
      end
    end
  
  end

end