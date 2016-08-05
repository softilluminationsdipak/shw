#require '../action_view/helpers/dynamic_form'
require  File.join(Rails.root , 'lib','dynamic_form','action_view','helpers','dynamic_form')

class ActionView::Base
  include DynamicForm
end
