class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.admin?
      can :manage, :all
    elsif user.editor?
      can :read, :all
      can :create, [Post, Comment]
      can :update, Post
      can :destroy, Comment
    else
      can :read, :all
      can :create, [Post, Comment]
      can [:update, :destroy], Post, user_id: user.id
      can [:update, :destroy], Comment, user_id: user.id
    end
  end
end