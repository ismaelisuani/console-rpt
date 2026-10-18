class ApplicationRecord < ActiveRecord::Base
  include Paginatable

  primary_abstract_class
end
