class AuthToken < ActiveRecord::Base
	belongs_to :partner
	attr_accessible :auth_token
end
