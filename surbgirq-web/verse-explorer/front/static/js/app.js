$( document ).ready(function() {
    // json formatting
    $('.jsonpanel').jsonFormatter({
        // The number of spaces a tab
        tab: '  ',

        // Specifies if object's keys should be quoted in the formatted output.
        quoteKeys: true,

        // Specifies if arrays and objects are collapsible in the formatted output.
        collapsible: true,

        // Specifies if the original element is hidden.
        hideOriginal: true
    });

    // this keep on top, first add modal dialog html
    var elDiv = document.createElement('div');
    elDiv.innerHTML = modalHTML;
    document.body.appendChild(elDiv.children[0]);

    var filterFlag = parseInt($('#filterFlag').val());
    var ts =  $('#filters > li > input:checkbox').toArray();
     ts.forEach(function(item, index){
         var elFlag = parseInt($(item).data('flag'));
         if((filterFlag & elFlag) == elFlag){
             $(item).attr('checked', true);
         }
     });

    $('#btnFilter').on('click', function () {
        window.location.href = '/blocks';
        MicroModal.close("modal-1");

    })

    function updateFilters(){
        var tsArr = $('#filters > li > input:checkbox:checked').map((i,e)=>$(e).data('flag')).toArray().reduce((a,v) => a + v, 0);
        $('#filterFlag').val(tsArr);
        document.cookie = tsArr;
   }


    $('#filters > li > input:checkbox').on('click', function(){
       updateFilters();
     });

MicroModal.init({
    onShow: modal => initModalDialog(modal),
    onClose: modal => console.info(`${modal.id} is hidden`), // [2]
    openTrigger: 'data-custom-open', // [3]
    closeTrigger: 'data-custom-close', // [4]
    disableScroll: true, // [5]
    disableFocus: false, // [6]
    awaitCloseAnimation: false, // [7]
    debugMode: true // [8]
  });


    var initModalDialog = function(modal){
        alert("initmodal");
    }

});

(function () {
  /**
   *
   * @type {Number | null}
   */
  var originalBlockCount = null;
  var blockCount = 0;
  var wssProtocol = location.protocol === 'https:' ? 'wss' : 'ws';
  var ws = new WebSocket(wssProtocol + '://' + window.location.host + '/block/channels/notify-new');
  ws.onmessage = function (msg) {
    var newCount = parseInt(msg.data);
    if (!isNaN(newCount)) {
      blockCount = newCount;
    }
    // Initialize originalBlockCount with first count from server
    if (originalBlockCount === null) {
      originalBlockCount = newCount;
    }
    $('#block_count').text(msg.data)
    console.debug(msg);
  }
  var originalTitle = document.title;

  function prependTitle (prefix) {
    document.title = prefix + ' ' + originalTitle;
  }

  var $blocks = $('.blocks-list');
  var $refreshBtn = $('.blocks-update');
  function handleBlockUpdates () {
    var updatesPending = false;
    var updatesCount = 0;
    if (isNaN(originalBlockCount)){
      updatesPending = true
    } else {
      updatesCount = blockCount - originalBlockCount
      updatesPending = updatesCount > 0
    }

    if (updatesPending) {
      $('.blocks-update', $blocks).text(renderUpdatedBlocksMsg(updatesCount));

      if (!$blocks.hasClass('updated')) {
        $($blocks).addClass('updated');
        $refreshBtn.slideDown();
      }
      prependTitle('(*)')
    }
  }

  function renderUpdatedBlocksMsg(count) {
    if (count === 1) {
      return "One block"
    } else {
      return count + " blocks"
    }
  }

  // do not bother with new blocks custom handler if there's no blocks list on page
  if ($blocks.length && $blocks.length > 0) {
    var blocksUrl = $('#menu-blocks').attr('href'); // see Lucid.Helper.mkMenu_ for ID generation
    $($refreshBtn).on('click', function () {window.location.href = blocksUrl;});
    var timeout = 10 * 1000 // milliseconds
    setInterval(handleBlockUpdates.bind(this), timeout)
  }

  // tx filtering
  var $menuFilter = $('#filter_menu');
    $($menuFilter ).on('click', function () {
        MicroModal.show('modal-1');

    })

})();


var modalHTML  =
`
<div class="modal micromodal-slide" id="modal-1" aria-hidden="true">
   <div class="modal__overlay" tabindex="-1" data-micromodal-close>
      <div class="modal__container" role="dialog" aria-modal="true" aria-labelledby="modal-1-title">
         <header class="modal__header">
            <h2 class="modal__title" id="modal-1-title">
               Hide blocks with:
            </h2>
            <button class="modal__close" aria-label="Close modal" data-micromodal-close></button>
         </header>
         <main class="modal__content" id="modal-1-content">
            <ul id="filters">
               <li>
                  <input type="checkbox" value="empty_tx" data-flag="1">
                  <label for="empty_tx"> Empty Tx </label>
               </li>
               <li>
                  <input type="checkbox" value="tick_tx" data-flag="2">
                  <label for="tick_tx"> Tick Tx  </label>
               </li>
               <li>
                  <input type="checkbox" value="refill_tx" data-flag="4">
                  <label for="refill_tx"> Refil Tx </label>
               </li>
            </ul>
         </main>
         <footer class="modal__footer">
            <button class="modal__btn modal__btn-primary" id="btnFilter">Filter</button>
            <button class="modal__btn" data-micromodal-close aria-label="Close this dialog window">Close</button>
         </footer>
      </div>
   </div>
</div>`
