class Group < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :prizes, dependent: :destroy

  validates :name, presence: true, length: { maximum: 60 }
  validates :invite_code, presence: true, uniqueness: true

  before_validation :assign_invite_code, on: :create

  def self.create_with_admin!(user, attributes)
    transaction do
      create!(attributes).tap { |group| group.memberships.create!(user: user, role: "admin") }
    end
  end

  def admin?(user) = memberships.exists?(user: user, role: "admin")
  def member?(user) = memberships.exists?(user: user)

  def prize_for(month) = prizes.find_by(month: month.beginning_of_month)

  def regenerate_invite_code!
    update!(invite_code: self.class.generate_invite_code)
  end

  def self.generate_invite_code
    loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless exists?(invite_code: code)
    end
  end

  private
    def assign_invite_code
      self.invite_code ||= self.class.generate_invite_code
    end
end
