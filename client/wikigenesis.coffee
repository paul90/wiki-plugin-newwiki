
# set an initial defaults to use...
# having a name, rather than a key, here would be good - but until there is a name to key lookup...
templateDefault = 'd85f3b7f57ff7597757d223e20932d1a6460e5c1abf23b1995b037964fb492c9'
lineupDefault = '#view/welcome-visitors/view/youre-new-here'
lineupRegex = /^#(?:(?:[a-z0-9-]+\/[a-z0-9-]+)\/*)+/

expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'
    .replace /\*(.+?)\*/g, '<i>$1</i>'

detag = (text) ->
  text
    .replace /<.+?>/g, ''

error = (text) ->
  "<div class=error style='color:#888;'>#{text}</div>"

form = (item, template) ->
  console.log "form", item
  """
    <div style="background-color:#eee; padding: 15px;">
      <p>Create new wiki using template:</p>
      <p class=template><img class='remote' src='#{template.url}/favicon.png' width=16
          title='#{template.site}' data-site='#{template.site}' data-slug='welcome-visitors'>
      #{template.title}<br><span class=description>#{template.description}</span></p>
      <div class=input><input type=text name=title placeholder="Wiki Name" required></div>
      <div class=input><input type=text name=description placeholder="Wiki Description"></div>
      <div class=input><input type=text name=wikiowner placeholder="Name of Wiki Owner" required></div>
      <button>Create Wiki</button>
  """

submit = ($item, item) ->

  data = {}
  valid = true
  $item.find('.error').remove()
  for div in $item.find('.input')
    input = ($div = $(div)).find('input').get(0)
    if input.checkValidity()
      data[input.name] = input.value
    else
      valid = false
      input.append error input.validationMessage
      $div.append error input.validationMessage
  return unless valid

  console.log "new wiki:", data

  rawTemplateDAT = ''
  rawLineUP = ''
  for line in item.text.split /\r?\n/
    continue unless words = line.match /\S+/g
    try
      [match, op, arg] = line.match(/^\s*(\w*)\s*(.*)$/)
      switch op
        when '' then
        when 'TEMPLATE'
          rawTemplateDAT = arg
        when 'LINEUP'
          rawLineUP = arg
    catch error
      console.log "New Wiki error:", error

  if rawTemplateDAT is ''
    rawTemplateDAT = templateDefault
  rawTemplateURL = "hyper://" + rawTemplateDAT
  templateURL = await beaker.hyperdrive.getInfo(rawTemplateURL).then( (x) -> x.key)

  if rawLineUP is ''
    rawLineUP = lineupDefault

  console.log "rawLineUP", rawLineUP, lineupRegex.test(rawLineUP)

  if rawLineUP.startsWith('#') and lineupRegex.test(rawLineUP)
    lineUP = rawLineUP
  else
    lineUP = lineupDefault

  await beaker.hyperdrive.forkDrive(templateURL, {
    title: data.title
    description: data.description
    detached: true
    prompt: false
  })
  .then (newWiki) ->
    console.log 'new wiki', newWiki
    console.log "New wiki created", newWiki.url

    wikiData = await newWiki.readFile('/wiki.json', 'json')
    .catch (error) ->
      console.log 'wiki.json missing from template wiki', error
    wikiData['author'] = data.wikiowner
    await newWiki.writeFile('/wiki.json', JSON.stringify(wikiData, null, '\t'))
    .then () ->
      newURL = newWiki.url + lineUP
      window.open newURL, newWiki.url
  .catch (error) ->
    console.log 'Error creating new wiki', error


emit = ($item, item) ->

  pluginOrigin = wiki.pluginRoutes["wikigenesis"]
  pluginCssUrl = pluginOrigin + '/client/wikigenesis.css'
  if (!$("link[href='#{pluginCssUrl}']").length)
    $("<link rel='stylesheet' href='#{pluginCssUrl}' type='text/css'>").appendTo("head")

  templateDAT = ''
  template = {}
  for line in item.text.split /\r?\n/
    continue unless words = line.match /\S+/g
    try
      [match, op, arg] = line.match(/^\s*(\w*)\s*(.*)$/)
      switch op
        when '' then
        when 'TEMPLATE'
          templateDAT = arg
    catch error
      console.log "New Wiki error:", error
  if templateDAT is ''
    templateDAT = templateDefault
  template.url = "hyper://" + templateDAT
  template.site = templateDAT
  templateArchive = beaker.hyperdrive.drive(template.url)
  templateInfo = await templateArchive.getInfo()
  template.title = templateInfo.title
  template.description = templateInfo.description
  $item.html form item, template
  $item.find('button').click ->
    submit $item, item

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item
  $item.find('input').dblclick (e) -> e.stopPropagation()

window.plugins.wikigenesis = {emit, bind} if window?
module.exports = {expand} if module?
