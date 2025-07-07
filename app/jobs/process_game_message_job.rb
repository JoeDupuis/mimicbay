class ProcessGameMessageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)

    return unless message.game.playing?
    return if message.character.nil? && !message.is_dm_whisper

    orchestrator = DmOrchestrator.new(message.game)
    orchestrator.process_message(message)
  end
end
