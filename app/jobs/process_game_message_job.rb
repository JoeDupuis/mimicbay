class ProcessGameMessageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    Rails.logger.info "ProcessGameMessageJob started for message #{message_id}"
    
    message = Message.find(message_id)
    Rails.logger.info "Found message from character: #{message.character&.name || 'DM'}"
    
    unless message.game.playing?
      Rails.logger.info "Game not playing, skipping"
      return
    end
    
    if message.character.nil? && !message.is_dm_whisper
      Rails.logger.info "Message has no character and not DM whisper, skipping"
      return
    end
    
    Rails.logger.info "Creating DM orchestrator"
    orchestrator = DmOrchestrator.new(message.game)
    
    Rails.logger.info "Processing message with orchestrator"
    result = orchestrator.process_message(message)
    
    Rails.logger.info "DM action result: #{result.inspect}"
    
    case result[:action]
    when "continue"
      process_dm_actions(result[:results]) if result[:results]
    when "wait"
      Rails.logger.info "DM decided to wait for player input"
    else
      Rails.logger.warn "Unknown DM action: #{result[:action]}"
    end
  rescue => e
    Rails.logger.error "Error processing game message: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end

  private

  def process_dm_actions(results)
    results.each do |result|
      if result[:message_id]
        Rails.logger.info "DM created message #{result[:message_id]}"
      elsif result[:error]
        Rails.logger.error "DM action error: #{result[:error]}"
      end
    end
  end
end