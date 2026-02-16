const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const http = require('http');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 700,
    height: 400,
    frame: false,
    transparent: true,
    show: false,
    skipTaskbar: true,
    focusable: false,
    resizable: false,
    minimizable: false,
    maximizable: false,
    alwaysOnTop: true,
    type: 'toolbar', 
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  mainWindow.setAlwaysOnTop(true, 'screen-saver', 1);
  mainWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  mainWindow.loadFile('index.html');
  // Disable context menu
  mainWindow.webContents.on('context-menu', (e) => {
    e.preventDefault();
  });
}

app.whenReady().then(() => {
  createWindow();

  // Simple HTTP server to receive terms from MPV
  const server = http.createServer((req, res) => {
    console.log(`[IPC] Request: ${req.method} ${req.url}`);
    if (req.method === 'POST') {
      let body = '';
      req.on('data', chunk => {
        body += chunk.toString();
      });
      req.on('end', () => {
        if (req.url === '/shutdown') {
          console.log('[IPC] Shutdown signal received');
          res.end('closing');
          setTimeout(() => app.quit(), 100);
          return;
        }

        if (req.url === '/hide') {
          console.log('[IPC] Hide signal received');
          res.end('hidden');
          mainWindow.hide();
          return;
        }

        try {
          const data = JSON.parse(body);
          if (data.term) {
            console.log('[IPC] Lookup for:', data.term);
            mainWindow.webContents.send('lookup-term', data);
            mainWindow.showInactive();
          }
        } catch (e) {
          console.error('Failed to parse request body', e);
        }
        res.end('ok');
      });
    } else {
      res.end('ready');
    }
  });

  server.on('error', (e) => {
    if (e.code === 'EADDRINUSE') {
      console.log('Address in use, exiting...');
      app.quit();
    }
  });

  server.listen(19634, '127.0.0.1', () => {
    console.log('Lookup IPC server listening on 19634');
  });

  // Parent PID monitoring
  const parentPidArg = process.argv.find(arg => arg.startsWith('--parent-pid='));
  const parentPid = parentPidArg ? parseInt(parentPidArg.split('=')[1]) : null;

  if (parentPid && !isNaN(parentPid)) {
    console.log(`[INFO] Monitoring parent PID: ${parentPid}`);
    setInterval(() => {
      try {
        // process.kill(pid, 0) throws if the process doesn't exist
        process.kill(parentPid, 0);
      } catch (e) {
        console.log('[INFO] Parent process died, shutting down...');
        app.quit();
      }
    }, 2000);
  }
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

ipcMain.on('hide-window', () => {
  mainWindow.hide();
});
