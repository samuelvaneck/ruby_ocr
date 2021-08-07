// send form
window.addEventListener('DOMContentLoaded', () => {
  const submitBtns = document.getElementsByClassName('submit-btn');
  Array.from(submitBtns).forEach((submitBtn) => {
    submitBtn.addEventListener('click', (event) => {
      event.preventDefault();
      const btn = event.target;
      const data = getFormData(btn);

      makeRequest(data).then((response) => response.body)
        .then(body => parseBody(body))
        .then(stream => new Response(stream))
        .then(response => response.blob())
        .then(blob => URL.createObjectURL(blob))
        .then(text => downloadBlob(text, data.format))
        .then(resetForm())
        .catch(err => console.error(err));
    });
  });

  const getFormData = (btn) => {
    const formElement = document.getElementById('download-form');
    let data = {}
    data.format = btn.dataset.format
    data.lines = new FormData(formElement).getAll('line');
    data.full_text = new FormData(formElement).getAll('full_text');

    return data;
  }

  const makeRequest = async (data) => {
    const response = await fetch('/download', {
      method: 'POST',
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
      body: JSON.stringify(data)
    });

    return response;
  }

  const parseBody = (body) => {
    const reader = body.getReader();

    return new ReadableStream({
      start(controller) {
        return pump();

        function pump() {
          return reader.read().then(({ done, value }) => {
            // When no more data needs to be consumed, close the stream
            if (done) {
              controller.close();
              return;
            }

            // Enqueue the next data chunk into our target stream
            controller.enqueue(value);
            return pump();
          });
        }
      }
    });
  }

  const downloadBlob = (text, format) => {
    let downloadLink = document.createElement("a");
    downloadLink.href = text;
    downloadLink.download = `download.${format}`
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
  }

  const resetForm = () => {
    const form = document.getElementById('download-form');
    const checkboxes = document.getElementsByName('line');
    Array.from(checkboxes).forEach((checkbox) => {
      checkbox.checked = false;
    })
  }
});


// Add spinner
window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('convert-btn').addEventListener('click', (event) => {
    const sWrapper = document.getElementById('spinner-wrapper');
    sWrapper.classList.remove('d-none');
    sWrapper.classList.add('d-flex');
  });
});
