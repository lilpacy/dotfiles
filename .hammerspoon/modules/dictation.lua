local command = "/Users/lilpacy/dotfiles/bin/local-dictation"

hs.hotkey.bind({}, "F18", function()
  hs.task.new(command, nil, { "toggle" }):start()
end)

return {
  command = command,
}
