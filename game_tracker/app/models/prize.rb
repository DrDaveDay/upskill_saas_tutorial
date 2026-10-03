class Prize < ApplicationRecord
  belongs_to :group

  normalizes :month, with: ->(month) { month.beginning_of_month }

  validates :description, presence: true, length: { maximum: 200 }
  validates :month, presence: true, uniqueness: { scope: :group_id }
end
