class User < ActiveRecord::Base

  has_many :posts

  def self.nonsense_method_for_test
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def is_admin
    false
  end

  def admin_export
    unless is_admin
      "monkey"
    end
  end

  if ActiveRecord::VERSION::MAJOR >= 3
    scope :a_limiter, :limit => 1
    scope :order_by, :order => "ID DESC"
    scope :nothing, :conditions => {:first_name => "unfound"}
  else
    named_scope :a_limiter, :limit => 1
    named_scope :order_by, :order => "ID DESC"
    named_scope :nothing, :conditions => {:first_name => "unfound"}
  end

end

class Post < ActiveRecord::Base

  belongs_to :user

end

class Unexportable < ActiveRecord::Base

  belongs_to :user

end
