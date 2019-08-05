import File from howl.io
import signal from howl

parse = bundle_load 'parser'
match_compiler = bundle_load 'match_compiler'

reverse = (table) ->
  for i=1,#table/2
    j = #table - i + 1
    table[i], table[j] = table[j], table[i]

file_open_handler = (opts) ->
  {:file, :buffer} = opts

  configs = {}

  directory = file.parent
  while directory
    editorconfig = directory\join '.editorconfig'

    if editorconfig.exists
      root, sections = parse editorconfig, match_compiler
      relative_path = file\relative_to_parent editorconfig.parent

      file_config = {}

      for section in *sections
        if not section.recursive
          relative_path = File(relative_path).basename

        if section.pattern\match relative_path
          for key, value in pairs section.config
            file_config[key] = value

      if next file_config
        -- Table isn't empty
        table.insert configs, file_config

      if root
        break

    directory = directory.parent

  reverse configs

  collapsed_config = {}
  for config in *configs
    for key, value in pairs config
      if value.value == 'unset'
        collapsed_config[key] = nil
      else
        collapsed_config[key] = value

  for _, value in pairs collapsed_config
    value.spec\apply buffer, value.value

unload = ->
  signal.disconnect 'file-opened', file_open_handler

signal.connect 'file-opened', file_open_handler

{
  info: bundle_load'aisu'.meta
  :unload
}
