class @MarkdownEditingDescriptor extends XModule.Descriptor
  # TODO really, these templates should come from or also feed the cheatsheet
  @multipleChoiceTemplate : "( ) #{gettext 'incorrect'}\n( ) #{gettext 'incorrect'}\n(x) #{gettext 'correct'}\n"
  @checkboxChoiceTemplate: "[x] #{gettext 'correct'}\n[ ] incorrect\n[x] correct\n"
  @stringInputTemplate: "= #{gettext 'answer'}\n"
  @numberInputTemplate: "= #{gettext 'answer'} +- 0.001%\n"
  @selectTemplate: "[[#{gettext 'incorrect'}, (#{gettext 'correct'}), #{gettext 'incorrect'}]]\n"
  @headerTemplate: "#{gettext 'Header'}\n=====\n"
  @explanationTemplate: "[explanation]\n#{gettext 'Short explanation'}\n[explanation]\n"

  constructor: (element) ->
    @element = element

    if $(".markdown-box", @element).length != 0
      @markdown_editor = CodeMirror.fromTextArea($(".markdown-box", element)[0], {
      lineWrapping: true
      mode: null
      })
      @setCurrentEditor(@markdown_editor)
      # Add listeners for toolbar buttons (only present for markdown editor)
      @element.on('click', '.xml-tab', @onShowXMLButton)
      @element.on('click', '.format-buttons a', @onToolbarButton)
      @element.on('click', '.cheatsheet-toggle', @toggleCheatsheet)
      # Hide the XML text area
      $(@element.find('.xml-box')).hide()
    else
      @createXMLEditor()

  ###
  Creates the XML Editor and sets it as the current editor. If text is passed in,
  it will replace the text present in the HTML template.

  text: optional argument to override the text passed in via the HTML template
  ###
  createXMLEditor: (text) ->
    @xml_editor = CodeMirror.fromTextArea($(".xml-box", @element)[0], {
    mode: "xml"
    lineNumbers: true
    lineWrapping: true
    })
    if text
      @xml_editor.setValue(text)
    @setCurrentEditor(@xml_editor)
    $(@xml_editor.getWrapperElement()).toggleClass("CodeMirror-advanced");
    # Need to refresh to get line numbers to display properly.
    @xml_editor.refresh()
    #alert "here i can tell them to insert a button"
    ###
    ChangeBy: edxOnBaadal
    This code is to add a button to enable form input in Coding Problems. This is a hack,until we find a better solution.
    AFAIK in the editor, we have no way of telling the problem type, except for the XML code of the problem.
    So I will search the xml box using jquery and if a particular tag(specific to coding problem)is found, then the button will be shown.

    Tag currently used to decide if coding problem : coderesponse
    NOTE: This might change in future depending on current edx version,update the variable target_tag in the below code in that case.
    SOURCE: http://edx-partner-course-staff.readthedocs.org/en/latest/exercises_tools/external_graders.html#create-a-code-response-problem
    ###
    target_tag =  ///
                  <                 #should have opening bracket
                  \s*               #allow for spaces after that
                  /?                #</coderesponse> or <coderesponse>
                  \s*
                  coderesponse      # change this incase the tag name changes
                  (>| [^<\n]*>)     # <coderesponse> or <coderesponse {any_string}> but not <coderesponse{any_string}>
                  ///
    problem_xml = @xml_editor.getValue()
    if target_tag.test problem_xml
      @enableFormInput()
  
  ###
  The problem has been decided as a coding type, and we will now insert a button  and a form 
  The button will be inserted besides the 'Save' button
  ###
  enableFormInput: () =>
    #wrapper 'li' tag of save button
    save_button_wrapper_li = $('a.action-save').closest('li')
    console.log save_button_wrapper_li
    #insert the button by duplicating the 'Save' button
    copy = save_button_wrapper_li.clone().insertBefore(save_button_wrapper_li)
    console.log copy
    copy.find('a').text('Create using form').removeClass('action-save')
    #Create a form

    form = 
    '
    <div id="problem-form" class="edit-xblock-modal">
      <div class="modal-header"> 
        <h2 class="title modal-window-title">  
          Coding Problem XML generator 
        </h2>
      </div> 
      <div class="modal-content">  
        <div id="statement-inputs">
        </div>
        <div id="language-options" style="display:none">
        </div>
        <div id="initial-text" style="display:none">
        </div>
      </div>
    </div>
    '
    #popup = $(form).insertAfter($('div > div.modal-window.modal-editor.confirm.modal-lg.modal-type-problem'))
    popup = $(form).appendTo($('div.modal-window.modal-editor.confirm.modal-lg.modal-type-problem'))

    languages = [
            {name:'cpp',mode:'text/x-c++src'},
            {name:'java',mode:'text/x-java'},
            {name:'python',mode:'python'}]
    segments = [
          'Statement',
          'Input',
          'Output',
          'Example',
          'Constraints']
    curLang = '';
    render = ->
      probSegs = '<ul>'
      
      for segment in segments
        probSegs += '<li><label>' + segment + '</label> <textarea id="' + segment + '-text"></textarea></li>'
      probSegs += '</ul><button id="goToLangSelect" >Next</button>'
      probSegs += '<button id="closeIt" style:"inline-block">Close</button>'
      $('#statement-inputs',popup).html probSegs
      checkboxes = '<ul>'
      
      for language in languages
        checkboxes += "<li><label>"+language.name+'</label>
              <input type="checkbox" id="'+language.name+'-select"/>
            </li>';
      checkboxes += '</ul><label>Is code-snippet</label>
          <input type="checkbox" id="isCodeSnippet"/>
          <button id="backToStatInpt">Back</button>
          <button id="Next-button" style="display:none" >Next</button>
          <button id="Submit-button" style="display:inline-block" >Submit</button>
          <button id="closeIt" style:"inline-block">Close</button>'
          
      $('#language-options',popup).html checkboxes
      finHTML = '<select id="lang-select" ></select>'
      for language in languages
        textboxes = '<textarea id="'+language.name+'-txt1"></textarea>
                <textarea id="'+language.name+'-txt3"></textarea>'
        finHTML += '<div id="'+language.name+'-txt" style="display:none">'+textboxes+'</div>'
      finHTML+='<button id="backToLangSelect">Back</button>
          <button id="finalSubmit">Submit</button>
          <button id="closeIt" style:"inline-block">Close</button>';
      $("#initial-text",popup).html finHTML
    
    render()

    hideShow = (hideId,showId)->
      $("##{hideId}",popup).hide()
      $("##{showId}",popup).show()

    $('#closeIt',popup).click ()->
      popup.hide()
      $('statement-inputs',popup).show()
      $('language-options',popup).hide()
      $('initial-text',popup).hide()

    $('#goToLangSelect',popup).click ()->
      hideShow 'statement-inputs','language-options'
        
    $('#isCodeSnippet',popup).click ()->
      if($('#isCodeSnippet',popup)[0].checked)
        hideShow 'Submit-button','Next-button'
      else
        hideShow 'Next-button','Submit-button'
    
    $('#backToStatInpt',popup).click ()->
      hideShow 'language-options','statement-inputs'
    
    $('#Next-button',popup).click ()->
      isFirst = true
      insrtHTML = ''
      for language in languages
        $("##{language.name}-txt",popup).hide()
        if ($('#'+language.name+'-select',popup)[0].checked)
          if isFirst
            $("##{language.name}-txt",popup).show()
            isFirst = false
            curLang = language.name+'-txt'
          $("##{language.name}-txt1",popup).show()
          $("##{language.name}-txt3",popup).show()
          insrtHTML += '<option id="'+language.name+'-option" value="'+language.name+'-txt">'+language.name+'</option>'
      $('#lang-select').html insrtHTML
      hideShow 'language-options','initial-text'


    $('#Submit-button,#finalSubmit',popup).click ()=>
      finXML = '<problem><text>'
      isCodeSnippet= $('#isCodeSnippet',popup)[0].checked
      for segment in segments
        text= $("##{segment}-text",popup)[0].value
        if(text.length>0)
          finXML += '<h1><b>'+segment+'</b></h1> '+parseInput text
      finXML += '</text> <select class="lang-options" style="margin-left:90%">'
      checkedLang=[]
      for language in languages
        if($("##{language.name}-select",popup)[0].checked)
          checkedLang.push(language)
          finXML+='<option value="'+language.mode+'">'+language.name+'</option> '
      finXML+='</select>'
      if(isCodeSnippet)
        finXML+='<div>'
        for language in checkedLang 
          finXML+='<div class="code-snippet code-stub" id="'+language.name+
              '" data-mode="'+language.mode+'" style="background-color:#000"  ><![CDATA['+
              $("##{language.name}-txt1",popup)[0].value+']]></div>'
        finXML += '</div>'
      finXML += '<span></span>
      <coderesponse queuename="cpp-queue">
        <textbox mode="'+(checkedLang[0]).mode+'" tabsize="4" />
        <codeparam>
          <initial_display><![CDATA[
    ]]> </initial_display>
          <grader_payload>
    {"problem_name": "Lecture2Problem1"}
        </grader_payload>
        </codeparam>
      </coderesponse>'
      if(isCodeSnippet)
        finXML += '<div id="last-code-stub">'
        for language in checkedLang
          finXML += '<div class="code-snippet code-stub" id="'+language.name+
              '" data-mode="'+language.mode+'" style="background-color:#000"  ><![CDATA['+
              $("##{language.name}-txt3",popup)[0].value+']]></div>'
        finXML+='</div>'
      finXML+='</problem>'
      @xml_editor.setValue finXML
      popup.hide()
      $('statement-inputs',popup).show()
      $('language-options',popup).hide()
      $('initial-text',popup).hide()
      

    $('#backToLangSelect',popup).click ()->
      hideShow 'initial-text','language-options'

    $('#lang-select',popup).change ()->
      newLang = $('#lang-select',popup)[0].value
      hideShow curLang,newLang
      curLang = newLang

    parseInput = (s)->
      isMathBlock = false;
      result = '<p>'
      while(s.length>1)
        if(s.charAt(0)=='$'&&s.charAt(1)=='$')
          if(isMathBlock)
            result=result+'$</math>\n'
            isMathBlock=false
          else
            result=result+'<math>$'
            isMathBlock=true
          s=s.substr(2,s.length-2)
        else if(s.charAt(0)=='\n')
          result=result+'\n</p><p>'
          s=s.substr(1,s.length-1)
        else if(s.charAt(0)==' ')
          result=result+'&#160;'
          s=s.substr(1,s.length-1)
        else
          result=result.concat(s.charAt(0));
          s=s.substr(1,s.length-1)
      if(s.length==1)
        result=result+s;
      return result+'</p>'
    
      
            

    copy.click () =>
      popup.css {
        'background-color': '#fff';
        'position': 'absolute';
        'width': '100%';
        'height': '100%';
        'top': '0px';
        'left': '0px';
        'z-index': 1000;
      }
      popup.show()
      return


  ###
  User has clicked to show the XML editor. Before XML editor is swapped in,
  the user will need to confirm the one-way conversion.
  ###
  onShowXMLButton: (e) =>
    e.preventDefault();
    if @cheatsheet && @cheatsheet.hasClass('shown')
      @cheatsheet.toggleClass('shown')
      @toggleCheatsheetVisibility()
    if @confirmConversionToXml()
      @createXMLEditor(MarkdownEditingDescriptor.markdownToXml(@markdown_editor.getValue()))
      # Put cursor position to 0.
      @xml_editor.setCursor(0)
      # Hide markdown-specific toolbar buttons
      $(@element.find('.editor-bar')).hide()

  ###
  Have the user confirm the one-way conversion to XML.
  Returns true if the user clicked OK, else false.
  ###
  confirmConversionToXml: ->
    # TODO: use something besides a JavaScript confirm dialog?
    return confirm(gettext "If you use the Advanced Editor, this problem will be converted to XML and you will not be able to return to the Simple Editor Interface.\n\nProceed to the Advanced Editor and convert this problem to XML?")

  ###
  Event listener for toolbar buttons (only possible when markdown editor is visible).
  ###
  onToolbarButton: (e) =>
    e.preventDefault();
    selection = @markdown_editor.getSelection()
    revisedSelection = null
    switch $(e.currentTarget).attr('class')
      when "multiple-choice-button" then revisedSelection = MarkdownEditingDescriptor.insertMultipleChoice(selection)
      when "string-button" then revisedSelection = MarkdownEditingDescriptor.insertStringInput(selection)
      when "number-button" then revisedSelection = MarkdownEditingDescriptor.insertNumberInput(selection)
      when "checks-button" then revisedSelection = MarkdownEditingDescriptor.insertCheckboxChoice(selection)
      when "dropdown-button" then revisedSelection = MarkdownEditingDescriptor.insertSelect(selection)
      when "header-button" then revisedSelection = MarkdownEditingDescriptor.insertHeader(selection)
      when "explanation-button" then revisedSelection = MarkdownEditingDescriptor.insertExplanation(selection)
      else # ignore click

    if revisedSelection != null
      @markdown_editor.replaceSelection(revisedSelection)
      @markdown_editor.focus()

  ###
  Event listener for toggling cheatsheet (only possible when markdown editor is visible).
  ###
  toggleCheatsheet: (e) =>
    e.preventDefault();
    if !$(@markdown_editor.getWrapperElement()).find('.simple-editor-cheatsheet')[0]
      @cheatsheet = $($('#simple-editor-cheatsheet').html())
      $(@markdown_editor.getWrapperElement()).append(@cheatsheet)

    @toggleCheatsheetVisibility()

    setTimeout (=> @cheatsheet.toggleClass('shown')), 10


  ###
  Function to toggle cheatsheet visibility.
  ###
  toggleCheatsheetVisibility: () =>
    $('.modal-content').toggleClass('cheatsheet-is-shown')

  ###
  Stores the current editor and hides the one that is not displayed.
  ###
  setCurrentEditor: (editor) ->
    if @current_editor
      $(@current_editor.getWrapperElement()).hide()
    @current_editor = editor
    $(@current_editor.getWrapperElement()).show()
    $(@current_editor).focus();

  ###
  Called when save is called. Listeners are unregistered because editing the block again will
  result in a new instance of the descriptor. Note that this is NOT the case for cancel--
  when cancel is called the instance of the descriptor is reused if edit is selected again.
  ###
  save: ->
    @element.off('click', '.xml-tab', @changeEditor)
    @element.off('click', '.format-buttons a', @onToolbarButton)
    @element.off('click', '.cheatsheet-toggle', @toggleCheatsheet)
    if @current_editor == @markdown_editor
        {
            data: MarkdownEditingDescriptor.markdownToXml(@markdown_editor.getValue())
            metadata:
              markdown: @markdown_editor.getValue()
        }
    else
       {
          data: @xml_editor.getValue()
          nullout: ['markdown']
       }

  @insertMultipleChoice: (selectedText) ->
    return MarkdownEditingDescriptor.insertGenericChoice(selectedText, '(', ')', MarkdownEditingDescriptor.multipleChoiceTemplate)

  @insertCheckboxChoice: (selectedText) ->
    return MarkdownEditingDescriptor.insertGenericChoice(selectedText, '[', ']', MarkdownEditingDescriptor.checkboxChoiceTemplate)

  @insertGenericChoice: (selectedText, choiceStart, choiceEnd, template) ->
    if selectedText.length > 0
      # Replace adjacent newlines with a single newline, strip any trailing newline
      cleanSelectedText = selectedText.replace(/\n+/g, '\n').replace(/\n$/,'')
      lines =  cleanSelectedText.split('\n')
      revisedLines = ''
      for line in lines
        revisedLines += choiceStart
        # a stand alone x before other text implies that this option is "correct"
        if /^\s*x\s+(\S)/i.test(line)
          # Remove the x and any initial whitespace as long as there's more text on the line
          line = line.replace(/^\s*x\s+(\S)/i, '$1')
          revisedLines += 'x'
        else
          revisedLines += ' '
        revisedLines += choiceEnd + ' ' + line + '\n'
      return revisedLines
    else
      return template

  @insertStringInput: (selectedText) ->
    return MarkdownEditingDescriptor.insertGenericInput(selectedText, '= ', '', MarkdownEditingDescriptor.stringInputTemplate)

  @insertNumberInput: (selectedText) ->
    return MarkdownEditingDescriptor.insertGenericInput(selectedText, '= ', '', MarkdownEditingDescriptor.numberInputTemplate)

  @insertSelect: (selectedText) ->
    return MarkdownEditingDescriptor.insertGenericInput(selectedText, '[[', ']]', MarkdownEditingDescriptor.selectTemplate)

  @insertHeader: (selectedText) ->
    return MarkdownEditingDescriptor.insertGenericInput(selectedText, '', '\n====\n', MarkdownEditingDescriptor.headerTemplate)

  @insertExplanation: (selectedText) ->
    return MarkdownEditingDescriptor.insertGenericInput(selectedText, '[explanation]\n', '\n[explanation]', MarkdownEditingDescriptor.explanationTemplate)

  @insertGenericInput: (selectedText, lineStart, lineEnd, template) ->
    if selectedText.length > 0
      # TODO: should this insert a newline afterwards?
      return lineStart + selectedText + lineEnd
    else
      return template

# We may wish to add insertHeader. Here is Tom's code.
# function makeHeader() {
#  var selection = simpleEditor.getSelection();
#  var revisedSelection = selection + '\n';
#  for(var i = 0; i < selection.length; i++) {
#revisedSelection += '=';
#  }
#  simpleEditor.replaceSelection(revisedSelection);
#}
#
  @markdownToXml: (markdown)->
    toXml = `function (markdown) {
      var xml = markdown,
          i, splits, scriptFlag;

      // replace headers
      xml = xml.replace(/(^.*?$)(?=\n\=\=+$)/gm, '<h1>$1</h1>');
      xml = xml.replace(/\n^\=\=+$/gm, '');

      // group multiple choice answers
      xml = xml.replace(/(^\s*\(.{0,3}\).*?$\n*)+/gm, function(match, p) {
        var choices = '';
        var shuffle = false;
        var options = match.split('\n');
        for(var i = 0; i < options.length; i++) {
          if(options[i].length > 0) {
            var value = options[i].split(/^\s*\(.{0,3}\)\s*/)[1];
            var inparens = /^\s*\((.{0,3})\)\s*/.exec(options[i])[1];
            var correct = /x/i.test(inparens);
            var fixed = '';
            if(/@/.test(inparens)) {
              fixed = ' fixed="true"';
            }
            if(/!/.test(inparens)) {
              shuffle = true;
            }
            choices += '    <choice correct="' + correct + '"' + fixed + '>' + value + '</choice>\n';
          }
        }
        var result = '<multiplechoiceresponse>\n';
        if(shuffle) {
          result += '  <choicegroup type="MultipleChoice" shuffle="true">\n';
        } else {
          result += '  <choicegroup type="MultipleChoice">\n';
        }
        result += choices;
        result += '  </choicegroup>\n';
        result += '</multiplechoiceresponse>\n\n';
        return result;
      });

      // group check answers
      xml = xml.replace(/(^\s*\[.?\].*?$\n*)+/gm, function(match) {
          var groupString = '<choiceresponse>\n',
              options, value, correct;

          groupString += '  <checkboxgroup direction="vertical">\n';
          options = match.split('\n');

          for (i = 0; i < options.length; i += 1) {
              if(options[i].length > 0) {
                  value = options[i].split(/^\s*\[.?\]\s*/)[1];
                  correct = /^\s*\[x\]/i.test(options[i]);
                  groupString += '    <choice correct="' + correct + '">' + value + '</choice>\n';
              }
          }

          groupString += '  </checkboxgroup>\n';
          groupString += '</choiceresponse>\n\n';

          return groupString;
      });

      // replace string and numerical
      xml = xml.replace(/(^\=\s*(.*?$)(\n*or\=\s*(.*?$))*)+/gm, function(match, p) {
          // Split answers
          var answersList = p.replace(/^(or)?=\s*/gm, '').split('\n'),

              processNumericalResponse = function (value) {
                  var params, answer, string;

                  if (_.contains([ '[', '(' ], value[0]) && _.contains([ ']', ')' ], value[value.length-1]) ) {
                    // [5, 7) or (5, 7), or (1.2345 * (2+3), 7*4 ]  - range tolerance case
                    // = (5*2)*3 should not be used as range tolerance
                    string = '<numericalresponse answer="' + value +  '">\n';
                    string += '  <formulaequationinput />\n';
                    string += '</numericalresponse>\n\n';
                    return string;
                  }

                  if (isNaN(parseFloat(value))) {
                      return false;
                  }

                  // Tries to extract parameters from string like 'expr +- tolerance'
                  params = /(.*?)\+\-\s*(.*?$)/.exec(value);

                  if(params) {
                      answer = params[1].replace(/\s+/g, ''); // support inputs like 5*2 +- 10
                      string = '<numericalresponse answer="' + answer + '">\n';
                      string += '  <responseparam type="tolerance" default="' + params[2] + '" />\n';
                  } else {
                      answer = value.replace(/\s+/g, ''); // support inputs like 5*2
                      string = '<numericalresponse answer="' + answer + '">\n';
                  }

                  string += '  <formulaequationinput />\n';
                  string += '</numericalresponse>\n\n';

                  return string;
              },

              processStringResponse = function (values) {
                  var firstAnswer = values.shift(), string;

                  if (firstAnswer[0] === '|') { // this is regexp case
                      string = '<stringresponse answer="' + firstAnswer.slice(1).trim() +  '" type="ci regexp" >\n';
                  } else {
                      string = '<stringresponse answer="' + firstAnswer +  '" type="ci" >\n';
                  }

                  for (i = 0; i < values.length; i += 1) {
                      string += '  <additional_answer>' + values[i] + '</additional_answer>\n';
                  }

                  string +=  '  <textline size="20"/>\n</stringresponse>\n\n';

                  return string;
              };

          return processNumericalResponse(answersList[0]) || processStringResponse(answersList);
      });

      // replace selects
      xml = xml.replace(/\[\[(.+?)\]\]/g, function(match, p) {
          var selectString = '\n<optionresponse>\n',
              correct, options;

          selectString += '  <optioninput options="(';
          options = p.split(/\,\s*/g);

          for (i = 0; i < options.length; i += 1) {
              selectString += "'" + options[i].replace(/(?:^|,)\s*\((.*?)\)\s*(?:$|,)/g, '$1') + "'" + (i < options.length -1 ? ',' : '');
          }

          selectString += ')" correct="';
          correct = /(?:^|,)\s*\((.*?)\)\s*(?:$|,)/g.exec(p);

          if (correct) {
              selectString += correct[1];
          }

          selectString += '"></optioninput>\n';
          selectString += '</optionresponse>\n\n';

          return selectString;
      });

      // replace explanations
      xml = xml.replace(/\[explanation\]\n?([^\]]*)\[\/?explanation\]/gmi, function(match, p1) {
          var selectString = '<solution>\n<div class="detailed-solution">\nExplanation\n\n' + p1 + '\n</div>\n</solution>';

          return selectString;
      });
      
      // replace labels
      // looks for >>arbitrary text<< and inserts it into the label attribute of the input type directly below the text. 
      var split = xml.split('\n');
      var new_xml = [];
      var line, i, curlabel, prevlabel = '';
      var didinput = false;
      for (i = 0; i < split.length; i++) {
        line = split[i];
        if (match = line.match(/>>(.*)<</)) {
          curlabel = match[1].replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
          line = line.replace(/>>|<</g, '');
        } else if (line.match(/<\w+response/) && didinput && curlabel == prevlabel) {
          // reset label to prevent gobbling up previous one (if multiple questions)
          curlabel = '';
          didinput = false;
        } else if (line.match(/<(textline|optioninput|formulaequationinput|choicegroup|checkboxgroup)/) && curlabel != '' && curlabel != undefined) {
          line = line.replace(/<(textline|optioninput|formulaequationinput|choicegroup|checkboxgroup)/, '<$1 label="' + curlabel + '"');
          didinput = true;
          prevlabel = curlabel;
        }
        new_xml.push(line);
      }
      xml = new_xml.join('\n');

      // replace code blocks
      xml = xml.replace(/\[code\]\n?([^\]]*)\[\/?code\]/gmi, function(match, p1) {
          var selectString = '<pre><code>\n' + p1 + '</code></pre>';

          return selectString;
      });

      // split scripts and preformatted sections, and wrap paragraphs
      splits = xml.split(/(\<\/?(?:script|pre).*?\>)/g);
      scriptFlag = false;

      for (i = 0; i < splits.length; i += 1) {
          if(/\<(script|pre)/.test(splits[i])) {
              scriptFlag = true;
          }

          if(!scriptFlag) {
              splits[i] = splits[i].replace(/(^(?!\s*\<|$).*$)/gm, '<p>$1</p>');
          }

          if(/\<\/(script|pre)/.test(splits[i])) {
              scriptFlag = false;
          }
      }

      xml = splits.join('');

      // rid white space
      xml = xml.replace(/\n\n\n/g, '\n');

      // surround w/ problem tag
      xml = '<problem>\n' + xml + '\n</problem>';

      return xml;
    }`
    return toXml markdown

