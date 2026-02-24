import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

/**
 * Echo configuration - for WebSocket real-time communication
 *
 * Supports both Reverb and Pusher server types
 */

// Detect which server to use
const broadcaster = import.meta.env.VITE_BROADCAST_DRIVER || 'reverb';

if (broadcaster === 'reverb') {
    /**
     * Reverb configuration
     * Reverb is Laravel's official WebSocket server
     */
    window.Echo = new Echo({
        broadcaster: 'reverb',
        key: import.meta.env.VITE_REVERB_APP_KEY,
        wsHost: import.meta.env.VITE_REVERB_HOST,
        wsPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
        wssPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
        forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'http') === 'https',
        enabledTransports: ['ws', 'wss'],
    });
} else if (broadcaster === 'pusher') {
    /**
     * Pusher configuration
     * Pusher is a third-party WebSocket service
     */
    window.Echo = new Echo({
        broadcaster: 'pusher',
        key: import.meta.env.VITE_PUSHER_APP_KEY,
        cluster: import.meta.env.VITE_PUSHER_APP_CLUSTER ?? 'mt1',
        wsHost: import.meta.env.VITE_PUSHER_HOST ?? `ws-${import.meta.env.VITE_PUSHER_APP_CLUSTER ?? 'mt1'}.pusher.com`,
        wsPort: 80,
        wssPort: 443,
        forceTLS: true,
        enabledTransports: ['ws', 'wss'],
    });
}

/**
 * Event listening examples
 */

// Listen to public channel
// window.Echo.channel('chat')
//     .listen('MessageSent', (e) => {
//         console.log('Message received:', e.message);
//         // Update UI
//     });

// Listen to private channel (authentication required)
// window.Echo.private(`chat.${userId}`)
//     .listen('MessageSent', (e) => {
//         console.log('Private message received:', e.message);
//     });

// Listen to presence channel
// window.Echo.join(`presence.chat`)
//     .here((users) => {
//         console.log('Currently online users:', users);
//     })
//     .joining((user) => {
//         console.log('User joined:', user);
//     })
//     .leaving((user) => {
//         console.log('User left:', user);
//     });

// Listen to all events (for debugging)
// window.Echo.channel('chat')
//     .listen('.*', (e) => {
//         console.log('Event received:', e);
//     });

/**
 * Connection state monitoring (for debugging)
 */

// Monitor connection state changes
// window.Echo.connector.pusher.connection.bind('state_change', (states) => {
//     console.log('Connection state:', states.current);
// });

// Monitor connection errors
// window.Echo.connector.pusher.connection.bind('error', (err) => {
//     console.error('WebSocket connection error:', err);
// });

// Monitor disconnection
// window.Echo.connector.pusher.connection.bind('disconnected', () => {
//     console.log('WebSocket disconnected');
// });