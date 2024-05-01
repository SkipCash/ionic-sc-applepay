import { SplashScreen } from '@capacitor/splash-screen';

import { loadSCPGW } from '../../../src/index';


window.customElements.define(
  'capacitor-welcome',
  class extends HTMLElement {
    constructor() {
      super();

      SplashScreen.hide();

      const root = this.attachShadow({ mode: 'open' });

      root.innerHTML = `
    <style>
      :host {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
        display: flex;
        justify-content: center;
        align-items: center;
        width: 100%;
        height: 100vh; /* Use viewport height to fill the entire screen */
        margin: 0; /* Remove default margin */
        padding: 0; /* Remove default padding */
      }
      
      h1, h2, h3, h4, h5 {
        text-transform: uppercase;
      }
      
      .button {
        padding: 10px;
        background-color: #73B5F6;
        color: #fff;
        font-size: 0.9em;
        border: 0;
        border-radius: 3px;
        text-decoration: none;
        cursor: pointer;
      }
      
    </style>
    <div>
      <main>
        <p>
          <button class="button" id="start-payment">Start Payment</button>
        </p>
        <p>
          <button class="button" id="launch-webview">Launch WebView</button>
        </p>
      </main>
    </div>
    `;
    }

    async connectedCallback() {
      const self = this;

      
      self.shadowRoot.querySelector('#launch-webview').addEventListener(
        'click', function (e) {
          loadSCPGW(
            "https://skipcashtest.azurewebsites.net/pay/bf52e849-0d5c-43ad-9f39-c64e95d7eb42", // payUrl
            "Protection Checkout", // WebModal Title
            "https://www.wasim.wiki/?wc-api=wc_gateway_skipcash_check" // Return URL as it configured in Merchant Portal
          )
        }
      )

    }
  }
);

window.customElements.define(
  'capacitor-welcome-titlebar',
  class extends HTMLElement {
    constructor() {
      super();
      const root = this.attachShadow({ mode: 'open' });
      root.innerHTML = `
    <style>
      :host {
        position: relative;
        display: block;
        padding: 15px 15px 15px 15px;
        text-align: center;
        background-color: #73B5F6;
      }
      ::slotted(h1) {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
        font-size: 0.9em;
        font-weight: 600;
        color: #fff;
      }
    </style>
    <slot></slot>
    `;
    }
  }
);
