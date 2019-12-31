class MessageBroadcastJob < ApplicationJob
  
  queue_as :messages

  def perform(message_id)
    message = Message.find_by(id: message_id)
    if message
      serialized_data = ActiveModelSerializers::Adapter::Json.new(Messages::Serializer.new(message)).serializable_hash
      ActionCable.server.broadcast("conversations_#{message.conversation.id}_channel", serialized_data)
    else
      return "Message with id #{message_id} not found"
    end
  end

end