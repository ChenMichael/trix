#= require trix/models/selection_manager

class Trix.AutoComplete
   constructor: (@editor, @dropDownContainer, @strategies)->
      @autoCompleteOn = false
      @documentString = @editor.getDocument().toString()
      #@dropDownController = new Trix.DropDownController @editor, this, @strategies, @dropDown
      @startingPosition = 0
      @endingPosition = 0
      @strategyIndex = 0
      @numDropDownItems = 0
      @dropDownItem = '.autoComplete-item'
      @currentStrategy

      $(document).ready ->
         $(@dropDown).hide()

   autoCompleteHandler: ->
      newDocumentString = @editor.getDocument().toString()
      position = @editor.getPosition()

      @dropDownContainer.empty()
   #   $(@dropDownContainer).show()

      @documentString = newDocumentString
      @autoCompleteStart(newDocumentString[position - 1], position - 1)

      #@autoCompleteOn = false

   autoCompleteStart: (character, position) ->
      @autoCompleteOn = false
      searchForSymbol = true
      results = []
      currentString = ""

      currentString += character
      @endingPosition = position

      self = this

      do ->
         while searchForSymbol
            i = 0
            while i < self.strategies.length
               regexObj = self.strategies[i].match
               if regexObj.test(currentString)
                  searchForSymbol = false
                  self.autoCompleteOn = true
                  self.startingPosition = position
                  self.strategyIndex = i
                  self.currentStrategy = self.strategies[i]
                  return
               ++i

            # slight optimization by moving if statement before loop idk if care
            if currentString[0] == ' '
               searchForSymbol = false
               return
            else
               if position <= 0
                  searchForSymbol = false
                  return
               position--

               currentString = self.documentString[position] + currentString

      if @autoCompleteOn
         searchTerm = ""

         if @currentStrategy.index
            searchTerm = currentString.slice(@currentStrategy.index)

         @currentStrategy.search(searchTerm, @populateDropDown)

      return results

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
      return unless results?
      return unless @autoCompleteOn
      @numDropDownItems = 0

      @dropDownContainer.empty()
      @dropDownContainer.append("<ul class = 'dropdown-menu'></ul>")
      @dropDown = $('.dropdown-menu');

      @positionDropDown()

      @addDropDown result for result in results
      @dropDownContainer.show()

      @numDropDownItems = results.length
      @initEventListeners()

   addDropDown: (result)->
      if result[0] == '<'
         result = result.slice(1, -1)

      html = @currentStrategy.template(result)

      container = $('<li/>')
         .addClass('autoComplete-item')
         .attr({'tabindex' : 0, 'data-index' : @numDropDownItems})
         .append(html)

         #'<li class = autoComplete-item tabindex = ' + 0 + ' data-index = ' + @numDropDownItems + '></li>'

      #$(container).append(html)
      temp = '<li class = autoComplete-item tabindex = ' + 0 + ' data-index = ' + @numDropDownItems + '></li>'
      @dropDown.append(container)
      @numDropDownItems++

   insertAutoCompleteItem: (dropDownItem) ->
      $(dropDownItem).addClass("active")
      strategyIndex = @strategyIndex
      startingPosition = @startingPosition
      endingPosition = @endingPosition

      if @currentStrategy.extract
         HTML = @strategies[@strategyIndex].extract(dropDownItem[0])
      else
         HTML = dropDownItem[0].innerText

      return unless HTML?
      return unless endingPosition >= startingPosition

      @editor.setSelectedRange([startingPosition, endingPosition + 1])
      @editor.deleteInDirection("forward")

      @strategies[strategyIndex].replace(HTML, startingPosition, startingPosition)

      @autoCompleteEnd()

   initEventListeners: ->
      self = this
      $(@dropDownItem + "[data-index='0']").focus()

      $(window).on 'resize', () ->
         self.positionDropDown()

      $(window).on 'mousedown', () ->
         self.autoCompleteEnd()

      $('trix-editor').on 'mousewheel', () ->
         self.autoCompleteEnd()

      $(@dropDownItem).on 'focus', () ->
         $(this).addClass('active')
      $(@dropDownItem).on 'blur', () ->
         $(this).removeClass('active')
      $(@dropDownItem).on 'hover',
         (() ->
            $(this).focus()
            $(this).addClass('active')),
         (() ->
            $(this).removeClass('active')
         )

      $(@dropDownItem).on 'mousedown', () ->
         self.insertAutoCompleteItem($(this))

      $(@dropDownItem).on 'keydown', (event) ->
         currentDataIndex = parseInt($(this).attr('data-index'))
         nextDataIndex = 0
         jquerySelector = self.dropDownItem + "[data-index='" + nextDataIndex + "']"

         if event.keyCode == 38
            if currentDataIndex == 0
               nextDataIndex = self.numDropDownItems - 1
            else
               nextDataIndex = currentDataIndex - 1
            jquerySelector = self.dropDownItem + "[data-index='" + nextDataIndex + "']"
            $(this).blur()
            $(jquerySelector).focus()
            event.preventDefault()
         else if event.keyCode == 40
            if currentDataIndex == self.numDropDownItems - 1
               nextDataIndex = 0
            else
               nextDataIndex = currentDataIndex + 1
            jquerySelector = self.dropDownItem + "[data-index='" + nextDataIndex + "']"
            $(this).blur()
            $(jquerySelector).focus()
            event.preventDefault()
         else if (event.keyCode == 13 || event.keyCode == 9)
            self.insertAutoCompleteItem($(this))
            event.preventDefault()
            $('trix-editor').focus()
          else
             self.autoCompleteEnd();
             $('trix-editor').focus()


   #checkAutoComplete: (character, value) ->
      #@strategies[@strategyIndex].search()
      #if value.indexOf(character) >= 0
         #return value
      #else
         #return
