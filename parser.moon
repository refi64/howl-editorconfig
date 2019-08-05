import log from howl

-- Make the linter shut up.
spec_parsers = nil

spec_parsers =
  boolean: (value) =>
    switch value
      when 'true'
        return true
      when 'false'
        return false
      else
        return nil, 'Expected true or false'

  positive_integer: (value) =>
    int = tonumber value

    if not value\match '^%d+$' or int < 0
      return nil, 'Expected a positive integer'

    return int

  positive_integer_or_allowed_string: (value) =>
    if value == @allowed_string
      return value

    int = spec_parsers.positive_integer @, value
    if not int
      return nil, "Expected a positive integer or #{@allowed_string}"

    return int

  string_choice: (value) =>
    for choice in *@choices
      return value if value == choice

    return nil, "Expected one of #{table.concat @choices, ','}"

key_specs =
  root:
    parse: spec_parsers.boolean

  indent_style:
    parse: spec_parsers.string_choice
    choices: {'tab', 'space'}
    apply: (buffer, value) =>
      buffer.config.use_tabs = value == 'tab'

  indent_size:
    parse: spec_parsers.positive_integer_or_allowed_string
    allowed_string: 'tab'
    apply: (buffer, value) =>
      buffer.config.indent = if value == 'tab'
        buffer.config.tab_width
      else
        value

  tab_width:
    parse: spec_parsers.positive_integer
    apply: (buffer, value) =>
      buffer.config.tab_width = value

  end_of_line:
    parse: spec_parsers.string_choice
    choices: {'lf', 'crlf', 'cr'}
    apply: (buffer, value) =>
      buffer.eol = value\gsub('cr', '\r')\gsub('lf', '\n')

  charset:
    parse: spec_parsers.string_choice
    choices: {'latin1', 'utf-8', 'utf-16be', 'utf-16le', 'utf-8-bom'}
    apply: (buffer, value) =>
      -- TODO (when would anyone actually use this for anything but utf-8?)

  trim_trailing_whitespace:
    parse: spec_parsers.boolean
    apply: (buffer, value) =>
      buffer.config.strip_trailing_whitespace = value

  insert_final_newline:
    parse: spec_parsers.boolean
    apply: (buffer, value) =>
      buffer.config.ensure_newline_at_eof = value

  max_line_length:
    parse: spec_parsers.positive_integer_or_allowed_string
    allowed_string: 'off'
    apply: (buffer, value) =>
      if value != 'off'
        buffer.config.edge_column = value
        buffer.config.hard_wrap_column = value
        buffer.config.auto_reflow_text = true
      else
        buffer.config.edge_column = nil
        buffer.config.auto_reflow_text = false

class ParseContext
  new: (file, match_compiler) =>
    @file = file
    @match_compiler = match_compiler
    @line = nil
    @lineno = 0
    @root = false
    @sections = {}

  error: (message) =>
    log.error "#{@file}: #{@lineno}: #{message}: #{@line}"

  parse_section: =>
    section_name = @line\match '^%[(.*)%]$'
    if not section_name
      @error "Invalid section"
    else
      pattern = @.match_compiler section_name
      if not pattern
        @error "Invalid pattern in section"

      table.insert @sections,
        :pattern
        uncompiled: section_name
        recursive: section_name\match'/' != nil
        config: {}

  parse_setting: =>
    key, value = @line\match '^([%a_]+)%s*=%s*(.+)$'
    if not key or not value
      @error "Invalid setting"
      return

    if key == 'root'
      if #@sections != 0
        @error "root key must be at root"
        return
    elseif #@sections == 0
      @error "All keys but root must be in a section"
      return

    spec = key_specs[key]
    if not spec
      return

    local parsed_value

    if value != 'unset' or key == 'root'
      parsed_value, error = spec\parse value
      if error
        @error "Failed to parse value: #{error}"
        return

    if key == 'root'
      @root = parsed_value
    else
      @sections[#@sections].config[key] = {:spec, value: parsed_value}

  parse: =>
    @file\open 'r', (fh) ->
      while true
        @line = fh\read!
        break if not @line

        @lineno += 1

        @line = @line.stripped
        continue if @line.is_empty or @line\match '^%s*[#;]'

        if @line\match '^%['
          @parse_section!
        else
          @parse_setting!

    return @root, @sections

(...) ->
  args = {...}
  context = ParseContext unpack args
  return context\parse!
