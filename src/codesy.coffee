codesy =
  options :
    endpoint: "/api"
    version: "/v1"
    domain: "mysterious-badlands-8311.herokuapp.com/",
    form:
      heigth: 100
      width: 100
    url: ->
      "https://" + @domain
  form: null
  api:{}
  current:{url:null}

chrome.storage.local.get (data)->
  codesy.options.auth_token = data.auth_token 
 
codesy.api.get = (resource, ajax_params) ->
  ajax_params = ajax_params or {}
  $.ajax
    type: "get"
    url:  codesy.options.url() + resource
    data: ajax_params
    dataType: "html"

codesy.auth_token = ->
  if codesy.options.auth_token
    codesy.options.auth_token
  else
    codesy.getAuthOption()


codesy.api.put = (form) ->
  $.ajax
    beforeSend: (xhr,settings) ->
      xhr.setRequestHeader("Authorization","Token "+codesy.auth_token())
    type: form.attr('method')
    url: form.attr('action')
    data: form.serialize()
    dataType: "html"
    success:  ->
      codesy.newpage()
    error: (err)->
      console.log err
  
codesy.api.bid = (params) -> 
  codesy.api.get '/bid/',params 
  

codesy.isIssue = (url)->
  rx = /https:\/\/github.com\/.*\/issues\/./g
  rx.test url
  
codesy.positionForm = () ->
  footerTop = $(window).scrollTop()+$(window).height()-codesy.options.form.heigth
  footerLeft = $(window).width()-codesy.options.form.width
  if ($(document.body).height()+footerTop) > $(window).height() 
     codesy.form.css {position: "absolute", top: footerTop,left:footerLeft}
  else
     codesy.form.css {position: "static", top: footerTop,left:footerLeft}

codesy.appendForm = (cdsyForm) ->
  dfd = new $.Deferred()
  $("body").append cdsyForm
  if $("#codesy_bid_form").length > 0
    codesy.form = $("#codesy_bid_form")
    $(window)
      .scroll(codesy.positionForm)
      .resize(codesy.positionForm)
    codesy.positionForm()
    dfd.resolve()
  else
    dfd.reject()
  dfd.promise()  
  
codesy.newpage = ()->
  $("#codesy_bid_form").remove()
  if codesy.isIssue window.location.href
    codesy.api.bid({url:window.location.href}) 
      .done((html_form) ->
        console.log html_form
        codesy.appendForm(html_form)
          .done( ->
            codesy.form.submit( (e)->
              codesy.api.put(codesy.form)
              false
              )
            )
      )  
      .fail((data) ->
        console.log "$.ajax failed."
      )

chrome.runtime.onMessage.addListener (msg, sender, sendResponse)->
  console.log "xhr received"
  if msg.url
    codesy.newpage()

     
window.onpopstate = ->
  console.log "popstate"
  codesy.newpage()

codesy.newpage()