{handleEvent} = Trix

class Trix.AutoComplete
   constructor: (@editor, @editorElement, @dropDownContainer, @strategies)->
      @autoCompleteOn = false
      @documentString = @editor.getDocument().toString()
      @startingPosition = 0
      @endingPosition = 0
      @numDropDownItems = 0
      @currentStrategy

   autoCompleteHandler: ->
      @documentString = @editor.getDocument().toString()
      position = @editor.getPosition()

      @dropDownContainer.hide()

      return if position == 0

      @checkAutoComplete(@documentString[position - 1], position - 1)

   checkAutoComplete: (currentString, position) ->
      return unless currentString?
      @autoCompleteOn = false
      searchForSymbol = true
      results = []

      @endingPosition = position

      self = this

      while searchForSymbol
         if currentString[0] == ' '
            searchForSymbol = false
            break
         else if position < 0
            searchForSymbol = false
            break

         for strategy in self.strategies
            if strategy.trigger.test(currentString)
               searchForSymbol = false
               @autoCompleteOn = true
               @startingPosition = position
               @currentStrategy = strategy
               @searchTerm = currentString
               break

         position--
         currentString = @documentString[position] + currentString

      if @autoCompleteOn
         if @currentStrategy.index
            @searchTerm = @searchTerm.slice(@currentStrategy.index)

         @currentStrategy.search(@searchTerm, @populateDropDown)


   autoCompleteEnd: ->
      @autoCompleteOn = false
      @dropDownContainer.hide()
      @dropDownContainer.empty()

   # TODO Figure how to deal with situation where trix editor moves but does not change size
   positionDropDown: ->
      parentRange = $('trix-editor').offset()
      domRange = @editor.getClientRectAtPosition(@editor.getPosition() - 1)

      return unless domRange?

      topVal = domRange.top + domRange.height
      leftVal = domRange.left + domRange.width

      @dropDown.css({top: topVal, left: leftVal, position: 'fixed', 'z-index':100})

   populateDropDown: (results)=>
      return unless results? && results.length && @autoCompleteOn
      @numDropDownItems = 0

      @dropDownContainer.empty()
      @dropDownContainer.append("<ul class = 'dropdown-menu'></ul>")
      @dropDown = $('.dropdown-menu');

      @positionDropDown()

      @addDropDownItem result for result in results
      @dropDownContainer.show()

      @numDropDownItems = results.length
      @initEventListeners()

   addDropDownItem: (result)->
      html = @currentStrategy.template(result)

      container = $('<li/>')
         .addClass('autoComplete-item')
         .attr({'tabindex' : 0, 'data-index' : @numDropDownItems})
         .append(html)

      @dropDown.append(container)
      @numDropDownItems++

   insertAutoCompleteItem: (dropDownItem) ->
      dropDownItem.addClass("active")

      return if dropDownItem.children().prop("tagName") == "BB-LOADING"

      if @currentStrategy.extract
         HTML = @currentStrategy.extract(dropDownItem[0])
      else
         HTML = dropDownItem[0].innerText

      return unless HTML? && @endingPosition >= @startingPosition

      @editor.setSelectedRange([@startingPosition, @endingPosition + 1])
      @editor.deleteInDirection("forward")

      @currentStrategy.replace(HTML, @startingPosition)

      #@autoCompleteEnd()

   initEventListeners: ->
      self = this
      dropDownItemSelector = '.autoComplete-item'
      dropDownItemJQ = $(dropDownItemSelector)
      $(dropDownItemSelector + "[data-index='0']").focus()

      $(window).on 'resize', () ->
         self.positionDropDown()
      $(window).on 'mousedown', () ->
         self.autoCompleteEnd()

      $('trix-editor').on 'mousewheel', () ->
         self.autoCompleteEnd()

      dropDownItemJQ.on 'focus', () ->
         $(this).addClass('active')
      dropDownItemJQ.on 'blur', () ->
         $(this).removeClass('active')
      dropDownItemJQ.on 'hover',
         (() ->
            $(this).focus()
            $(this).addClass('active')),
         (() ->
            $(this).removeClass('active')
         )

      dropDownItemJQ.on 'mousedown', () ->
         self.insertAutoCompleteItem($(this))

      dropDownItemJQ.on 'keydown', (event) ->
         currentDataIndex = parseInt($(this).attr('data-index'))
         nextDataIndex = 0

         if event.keyCode == 38
            if currentDataIndex == 0
               nextDataIndex = self.numDropDownItems - 1
            else
               nextDataIndex = currentDataIndex - 1

            jquerySelector = dropDownItemSelector + "[data-index='" + nextDataIndex + "']"
            $(this).blur()
            $(jquerySelector).focus()
            event.preventDefault()
         else if event.keyCode == 40
            if currentDataIndex == self.numDropDownItems - 1
               nextDataIndex = 0
            else
               nextDataIndex = currentDataIndex + 1

            jquerySelector = dropDownItemSelector + "[data-index='" + nextDataIndex + "']"
            $(this).blur()
            $(jquerySelector).focus()
            event.preventDefault()
         else if event.keyCode == 13 || event.keyCode == 9
            self.insertAutoCompleteItem($(this))
            event.preventDefault()
            self.autoCompleteEnd()
            self.editorElement.focus()
         else if event.keycode == 16
            event.preventDefault()
         else
            self.autoCompleteEnd();
            self.editorElement.focus()
