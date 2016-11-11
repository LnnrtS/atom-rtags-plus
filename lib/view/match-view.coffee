{View} = require 'atom-space-pen-views'
{Range, CompositeDisposable} = require 'atom'

LeadingWhitespace = /^\s+/
removeLeadingWhitespace = (string) -> string.replace(LeadingWhitespace, '')

module.exports =
class MatchView extends View
  @content: (model, {filePath, match}) ->
    range = Range.fromObject(match.range)
    matchStart = range.start.column - match.lineTextOffset
    matchEnd = range.end.column - match.lineTextOffset
    prefix = removeLeadingWhitespace(match.lineText[0...matchStart])
    suffix = match.lineText[matchEnd..]

    @li class: 'search-result list-item', =>
      @span range.start.row + 1, class: 'line-number text-subtle'
      @span class: 'preview', outlet: 'preview', =>
        @span prefix
        @span match.matchText, class: 'match highlight-info', outlet: 'matchText'
        @span match.matchText, class: 'replacement highlight-success', outlet: 'replacementText'
        @span suffix

  initialize: (@model, {@filePath, @match}) ->
    @render()
    if fontFamily = atom.config.get('editor.fontFamily')
      @preview.css('font-family', fontFamily)

  attached: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add @model.getFindOptions().onDidChangeReplacePattern @render

  detached: -> @subscriptions.dispose()

  render: =>
    if @model.getFindOptions().replacePattern and @model.regex and not @model.replacedPathCount?
      replacementText = @match.matchText.replace(@model.regex, @model.getFindOptions().replacePattern)
      @replacementText.text(replacementText)
      @replacementText.show()
      @matchText.removeClass('highlight-info').addClass('highlight-error')
    else
      @replacementText.text('').hide()
      @matchText.removeClass('highlight-error').addClass('highlight-info')

  confirm: ->
    openInRightPane = atom.config.get('atom-rtags.openFindReferencesResultsInRightPane')
    options = {}
    switch atom.config.get('atom-rtags.openResultsWindowLocation')
      when 'tab' then null
      when 'rightPane' then options.split = 'left'
      when 'downPane' then options.split = 'up'
    options.initialLine = @match.range[0][0]
    options.initialColumn = @match.range[0][1]
    atom.workspace.open(@filePath, options)

  copy: ->
    atom.clipboard.write(@match.lineText)
