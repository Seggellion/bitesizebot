class CommandService
  # Hardcoded commands that should NOT be overwritten
  RESERVED_COMMANDS = %w[ping raffle gamble fellowship lembas coffer bingo addcmd delcmd]

  def self.process_command(text, is_mod, author_name)
    return "You do not have permission to manage commands." unless is_mod

    parts = text.split(" ", 3) # "!addcmd", "name", "response..."
    action = parts[0].downcase

    case action
    when "!addcmd"
      name = parts[1]&.downcase&.delete_prefix("!")
      response = parts[2]
      return "Usage: !addcmd <name> <response>" if name.blank? || response.blank?
      return "Command !#{name} is reserved and cannot be used." if RESERVED_COMMANDS.include?(name)

      cmd = CustomCommand.find_or_initialize_by(name: name)
      cmd.response = response
      cmd.author = author_name
      cmd.save!
      "Command !#{name} has been #{cmd.previously_new_record? ? 'added' : 'updated'}!"

    when "!delcmd"
      name = parts[1]&.downcase&.delete_prefix("!")
      return "Usage: !delcmd <name>" if name.blank?
      
      cmd = CustomCommand.find_by(name: name)
      if cmd&.destroy
        "Command !#{name} has been deleted."
      else
        "Command !#{name} not found."
      end
    end
  end
end