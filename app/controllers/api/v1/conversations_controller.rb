class Api::V1::ConversationsController < ApplicationController
  
  before_action :authenticate_api_v1_user!, only: [:create, :index, :show, :update]

  def index
    params[:user_id].to_i == current_api_v1_user.id ? conversations = Conversation.where(user1_id: params[:user_id]).or(Conversation.where(user2_id: params[:user_id])) : conversations = []
    render json: conversations, each_serializer: Conversations::IndexSerializer
  end

  def show
    conversation = Conversation.find(params[:id])
    conversation.user1_id == current_api_v1_user.id || conversation.user2_id == current_api_v1_user.id ? (render json: conversation, include: [message: [:user]], serializer: Conversations::ShowSerializer) : (render json: { error: 'You cannot perform this action!' }, status: 422)
  end

  def create
    conversation_exists = Conversation.where(user1_id: params[:user1_id], user2_id: params[:user2_id]).or(Conversation.where(user1_id: params[:user2_id], user2_id: params[:user1_id]))
    if conversation_exists.length == 1
      render json: { message: 'Conversation already exists', id: conversation_exists[0].id}, status: 200
    else
      conversation = Conversation.create(conversation_params)
      if conversation.persisted?
        user1 = current_api_v1_user
        user2 = User.where(id: conversation.user2_id)
        render json: { message: 'Successfully created', id: conversation.id }, status: 200
        ConversationsMailer.notify_user_new_conversation(user1, user2[0]).deliver
      end
    end
  end

  def update
    conversation = Conversation.find(params[:id])
    if conversation.user1_id == current_api_v1_user.id || conversation.user2_id == current_api_v1_user.id
      if conversation.hidden == nil
        conversation.update_attribute('hidden', params[:hidden])
        conversation.persisted? == true && (render json: { message: 'Success' }, status: 200)
      else 
        conversation.destroy
      end
    else
      render json: { error: 'You cannot perform this action!' }, status: 422
    end
  end


  private

  def conversation_params
    params.permit(:user1_id, :user2_id)
  end

end
