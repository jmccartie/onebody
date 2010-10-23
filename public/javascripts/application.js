function observeFields(func, frequency, fields) {
  observeFieldsValueMap = window.observeFieldsValueMap || {};
  $.each(fields, function(index, field){
    observeFieldsValueMap[field] = $('#'+field).val();
  });
  var observer = function() {
    for(var f in observeFieldsValueMap) {
      var currentValue = $('#'+f).val();
      if(observeFieldsValueMap[f] != currentValue) {
        observeFieldsValueMap[f] = currentValue;
        func(f);
        return;
      }
    }
  };
  setInterval(observer, frequency);
};

function custom_select_val(select_elm, prompt_text){
  if(val = prompt(prompt_text, '')) {
    var option = $('<option/>');
    option.val(val);
    option.html(val);
    option.attr('selected', true);
    option.appendTo(select_elm);
    return true;
  } else {
    return false;
  }
};

$('#share_picture_form').live('submit', function(){
  if($('#album_id').val() == '!') {
    return custom_select_val($('#album_id'), $('#share_picture_form').attr('data-album-prompt'));
  }
});
