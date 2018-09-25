
# set an initial defaults to use...
templateDefault = 'empty-site-fedwiki.hashbase.io'
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
  rawTemplateURL = "dat://" + rawTemplateDAT
  templateURL = await DatArchive.resolveName(rawTemplateURL)

  if rawLineUP is ''
    rawLineUP = lineupDefault

  console.log "rawLineUP", rawLineUP
  console.log "regex", lineupRegex.test(rawLineUP)

  if rawLineUP.startsWith('#') and lineupRegex.test(rawLineUP)
    lineUP = rawLineUP
  else
    lineUP = lineupDefault


  await DatArchive.fork(templateURL, {
    title: data.title
    description: data.description
    type: ['federated-wiki-site']
    prompt: false
    })
  .then (newWikiArchive) ->
    try
      rawData = await newWikiArchive.readFile('/wiki.json')
      parsedData = JSON.parse(rawData)
    catch error
      console.log "Error loading wiki.json:", error
    parsedData['author'] = data.wikiowner
    await newWikiArchive.writeFile('/wiki.json', JSON.stringify(parsedData, null, '\t'))

    newURL = newWikiArchive.url + lineUP
    console.log "newURL", newURL

    window.open(newURL, newWikiArchive.url)
  .catch (error) ->
    console.log "Creating New Wiki: ", error


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
  template.url = "dat://" + templateDAT
  template.site = templateDAT
  templateArchive = new DatArchive(template.url)
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
