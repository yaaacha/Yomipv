const { ipcRenderer } = require('electron');

const glossaryEl = document.getElementById('glossary-content');
const headerEl = document.getElementById('term-header');

ipcRenderer.on('lookup-term', async (event, data) => {
  console.log('[IPC] Received lookup data:', JSON.stringify(data));

  // Header rendering helper
  const renderHeader = (term, readingHtml) => {
    const cleanTerm = (term || '').trim();
    
    console.log(`[UI] Rendering header: term="${cleanTerm}"`);

    if (readingHtml && readingHtml !== cleanTerm) {
      headerEl.innerHTML = `
        <div class="term-display">
          <ruby>
            ${cleanTerm}
            <rt>${readingHtml}</rt>
          </ruby>
        </div>
      `;
    } else {
      headerEl.innerHTML = `
        <div class="term-display">
          <div class="term-expression">${cleanTerm}</div>
        </div>
      `;
    }
  };

  // Initial header update with available data
  renderHeader(data.term, data.reading);

  // Loading state display
  glossaryEl.innerHTML = '<div class="loading">Looking up...</div>';

  try {
    // Yomitan API request
    console.log('Sending request for:', data.term);
    
    // Iterate through API endpoints
    let result;
    const endpoints = [`http://127.0.0.1:19633/ankiFields`, `http://127.0.0.1:19633/api/ankiFields`];
    
    for (const url of endpoints) {
      try {
        console.log(`Trying endpoint: ${url}`);
        const response = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            text: data.term,
            type: 'term',
            markers: ['glossary', 'expression', 'reading', 'pitch-accent-categories', 'pitch-accents'],
            includeMedia: true
          })
        });

        if (response.ok) {
          result = await response.json();
          break;
        } else {
          console.warn(`Endpoint ${url} failed with status: ${response.status}`);
        }
      } catch (err) {
        console.warn(`Failed to fetch from ${url}:`, err);
      }
    }

    if (!result) {
      throw new Error('All Yomitan endpoints failed');
    }

    console.log('API Result:', result);

    const entries = (result && result.fields) || (result && result[0] && result[0].fields);
    const fields = entries ? (Array.isArray(entries) ? entries[0] : entries) : null;

    if (fields && (fields.glossary || fields.definition)) {
      // Use accurate reading from API results if available
      const term = fields.expression || data.term;
      
      // Prioritize pitch accents (first item) as reading
      let reading = fields.reading || data.reading;
      const pitchAccents = fields['pitch-accents'] || '';
      
      if (pitchAccents) {
        const tempPitch = document.createElement('div');
        tempPitch.innerHTML = pitchAccents;
        const firstPitch = tempPitch.querySelector('li');
        if (firstPitch) {
          reading = firstPitch.innerHTML;
          console.log('[UI] Using pitch accent for reading');
        }
      }

      renderHeader(term, reading);

      // Pitch accent coloring logic
      const pitchTarget = fields['pitch-accent-categories'] || '';
      console.log(`[UI] Pitch accent categories: "${pitchTarget}"`);
      
      const pitchColors = {
        'atamadaka': 'var(--pitch-red)',
        'heiban': 'var(--pitch-blue)',
        'nakadaka': 'var(--pitch-orange)',
        'odaka': 'var(--pitch-green)',
        'kifuku': 'var(--pitch-purple)'
      };

      // Extract first matching category from list
      const firstPitch = pitchTarget.split(/[\s,]+/).find(p => pitchColors[p.toLowerCase()]);
      
      if (firstPitch) {
        const color = pitchColors[firstPitch.toLowerCase()];
        console.log(`[UI] Applying pitch color: ${firstPitch} -> ${color}`);
        headerEl.style.setProperty('--pitch-accent-color', color);
      } else {
        headerEl.style.removeProperty('--pitch-accent-color');
      }

      let content = fields.glossary || fields.definition;
      
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = content;
      
      // Remove all images
      tempDiv.querySelectorAll('img').forEach(img => img.remove());
      
      // Join Jitendex glossary entries while preserving sense structure
      tempDiv.querySelectorAll('[data-dictionary*="Jitendex"]').forEach(dictEl => {
        dictEl.querySelectorAll('[data-sc-content="glossary"]').forEach(glossaryEl => {
          const children = Array.from(glossaryEl.childNodes);
          const definitions = [];
          
          children.forEach(node => {
            const isText = node.nodeType === Node.TEXT_NODE && node.textContent.trim().length > 0;
            const isElement = node.nodeType === Node.ELEMENT_NODE && !node.matches('span[data-details]');
            
            if (isText || isElement) {
              // Strip sense markers (①-⑳) from start of node
              let text = node.textContent;
              if (text.match(/^[①-⑳]/)) {
                text = text.replace(/^[①-⑳]\s*/, '');
                if (isText) {
                  node.textContent = text;
                } else {
                  node.innerText = text;
                }
              }
              
              if (text.trim().length > 0) {
                definitions.push(node);
              }
            }
          });
        });

        // Neutralize Jitendex list styles
        dictEl.querySelectorAll('li').forEach(li => {
          li.style.listStyle = 'none';
        });
      });

      glossaryEl.innerHTML = tempDiv.innerHTML;

      // Disable links
      glossaryEl.querySelectorAll('a, [data-link]').forEach(el => {
        el.onclick = (e) => e.preventDefault();
        el.style.pointerEvents = 'none';
        el.style.cursor = 'default';
      });

      // Sanitize dictionary titles
      glossaryEl.querySelectorAll('[data-dictionary]').forEach(el => {
        const titleEl = el.firstElementChild;
        if (titleEl) {
          titleEl.textContent = titleEl.textContent.replace(/[()]/g, '').trim();
        }
      });
    } else {
      glossaryEl.innerHTML = `No result found for "${data.term}".`;
    }
  } catch (e) {
    console.error('Lookup failed', e);
    glossaryEl.innerHTML = `Error fetching from Yomitan: ${e.message}`;
  }
});
