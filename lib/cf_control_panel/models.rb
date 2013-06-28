require 'sequel'
require 'uuidtools'
require 'cfoundry'
require 'date'
require 'cf_control_panel/validation_helper'

module CFControlPanel
  module Models
  
    class Account < Sequel::Model

      many_to_one :user, :class => "CFControlPanel::Models::User", :key => :user_id

      def orgs_summary
        now = DateTime.now.to_time

        puts "*** Last meta update for #{name} - #{updated_on} (#{((now - updated_on.to_time) / 60)} minutes)"
        puts "*** Account data is nil? - #{account_data.nil?}"

        if account_data.nil? or (((now - updated_on.to_time) / 60) > 60)
          puts "*** Refreshing account meta for #{name}"
          orgs = cf_client.organizations.sort_by(&:name)

          container = []
        
          orgs.each do |o|
            org = o.summary
            org[:spaces].each do |s| 
              begin
                s[:summary] = o.space_by_name(s[:name]).summary
              rescue CFoundry::NotAuthorized
                s[:summary] = "Not Authorized"
              end
            end
            container << org
          end

          puts "*** Updating account data.."
          update :account_data => container.to_json
          save_changes
        end

        account_data
      end

      private

      def cf_client
        auth_token = CFoundry::AuthToken.new auth_key
        CFoundry::Client.new endpoint, auth_token
      end

    end

    class User < Sequel::Model
      include CFControlPanel::ValidationHelper

      plugin :validation_helpers
      one_to_many :accounts, :class=>"CFControlPanel::Models::Account", :key=>:user_id

      def validate
        super
        
        # ID
        validates_presence :id
        validates_unique :id

        # EMAIL
        validates_format email_regex, :email 
        validates_presence :email
        validates_unique :email
      end

    end

  end
end

Sequel::Model.plugin :timestamps
CFControlPanel::Models::User.plugin :timestamps, :create=>:created_on, :update=>:updated_on, :force=>true, :update_on_create=>true
CFControlPanel::Models::Account.plugin :timestamps, :create=>:created_on, :update=>:updated_on, :force=>true, :update_on_create=>true