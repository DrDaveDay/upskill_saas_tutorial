class Membership < ApplicationRecord
  ROLES = %w[ admin member ].freeze

  belongs_to :user
  belongs_to :group

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :group_id, message: "is already in this group" }

  before_destroy :keep_an_admin

  def admin? = role == "admin"

  private
    def keep_an_admin
      return if destroyed_by_association || !admin?

      others = group.memberships.where.not(id: id)
      return if others.none? || others.exists?(role: "admin")

      errors.add(:base, "A group needs at least one admin. Make someone else an admin first.")
      throw :abort
    end
end
