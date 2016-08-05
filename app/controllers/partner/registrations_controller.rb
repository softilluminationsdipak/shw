class Partner::RegistrationsController < Devise::RegistrationsController
  
  layout "select"

  def new
   super
  end

	def create
		if !verify_recaptcha
      flash.delete :recaptcha_error
      build_resource
      resource.valid?
      resource.errors.add(:base, "There was an error with the recaptcha code below. Please re-enter the code.")
      clean_up_passwords(resource)
      respond_with_navigational(resource) { render :new }
    else
      flash.delete :recaptcha_error
      super
    end
  end
  
end