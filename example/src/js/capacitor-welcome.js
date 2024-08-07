import { SplashScreen } from '@capacitor/splash-screen';

import {  ScApplePay, loadSCPGW, initiatePayment, PaymentData, isWalletHasCards } from '../../../src/index';

ScApplePay.addListener(
  'payment_finished_webview_closed', () => {
    console.log("payment webview close success/failed");
    // after the webview closes it will trigger 'payment_finished_webview_closed' event
    // then you can check the payment id to see if the customer paid or not
  }
);


ScApplePay.addListener(
  'applepay_response', (data) => {
    const response = JSON.parse(data);
    console.log(response);
    // Handle payment response here...
    // you can get the payment details using the payment id after successful payment request.
    // send a GET request to SkipCash server /api/v1/payments/${paymentResponse.paymentId} and include your merchant
    // client id in the authorization header request to get the payment details.
    // for more details please refer to https://dev.skipcash.app/doc/api-integration/ 
  }
);

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
      
      self.shadowRoot.querySelector('#start-payment').addEventListener(
        'click', async function (e) {
          // initiate a new apple pay payment
          const paymentData = new PaymentData();
          paymentData.setEmail("example@example.com"); // mandatory
          paymentData.setAmount("1.00"); // mandatory
          paymentData.setFirstName("Skip"); // mandatory
          paymentData.setLastName("Cash"); // mandatory
          paymentData.setPhone("+97400000001"); // mandatory
          // here pass the name of the merchant identifier(you need to create a new one
          paymentData.setMerchantIdentifier("");      
          // from apple developer account of ur app ). 
          // please reachout to us on support@skipcash.com to get the manual that explains how
          // to generate your merchant identifier and to sign it with us to be able to use applepay

          /*
            // add your payment end point - you should create ur own endpoint for your merchant account
            // PLEASE REFER TO https://dev.skipcash.app/doc/api-integration/ for more information
            // on how to request a new payment (payment link) you need to implement that for your 
            // backend server to create endpoint to request a new payment and return the details 
            // you receive from skipcash server this package will use this endpoint to process your
            // customer payment using applepay. when u complete setuping & testing ur endpoint
            // please pass the link to below setPaymentLinkEndPoint //// method.
          */
          paymentData.setPaymentLinkEndPoint("");

          // paymentData.setAuthorizationHeader("");
          // set your endpoint authorizartion header, used to protect your endpoint from unauthorized access 

          //optional
          /*
            set transaction id (your system internal id assigned to specific transaction), 
            To track down a certain transaction, each transaction id should be unique.
          */
          paymentData.setTransactionId(""); //
          //optional
          /*
           Get each client payment details instantly after they make the payment directly to your server endpoint.
          */
          paymentData.setWebhookUrl(""); 

          paymentData.setSummaryItem("Total", `${paymentData.getAmount()}`); // Add payment summary item(s)
          
          const hasCards = await isWalletHasCards();
          if(hasCards){
            initiatePayment(paymentData);
          }else{
            // If no cards found, prompt user to setup new card
            setupNewCard();
          }
        }
      )

      self.shadowRoot.querySelector("#launch-webview").addEventListener(
        'click', function(e){
          loadSCPGW("", "", "");
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
