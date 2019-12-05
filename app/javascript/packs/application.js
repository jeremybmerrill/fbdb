// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)


document.addEventListener("turbolinks:load", function() {
    let timeouts = {}

    var token = document.getElementsByName('csrf-token')[0].content

    async function submitUpdatedWritablePage(txt, page_id, disclaimer){
        console.log("txt", txt, "page_id", page_id);
        const response = await fetch(`/writable_pages/${page_id}.json`, {
            method: 'PUT', // or 'PUT'
            body: JSON.stringify({notes: txt, disclaimer:disclaimer }),
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': token
            }
          });
        const myJson = await response.json();

    }

    document.addEventListener('keyup', function (event) {
        // If the clicked element doesn't have the right selector, bail
        if (!event.target.matches('.onkeyupdelay')) return;
        console.log(event.target.dataset.pageId)
        if (timeouts[event.target.dataset.pageId]){
            clearTimeout(timeouts[event.target.dataset.pageId])
        }
        timeouts[event.target.dataset.pageId] = setTimeout(() => submitUpdatedWritablePage(event.target.value, event.target.dataset.pageId, event.target.dataset.disclaimer), 3000);

    }, false);
});