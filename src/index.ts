import { registerPlugin } from '@capacitor/core';

import { ScApplePayPlugin } from './definitions'; //PaymentData


const ScApplePay = registerPlugin<ScApplePayPlugin>(
  'ScApplePay', {
    web: () => import('./web').then(m => new m.ScApplePayWeb()),
  }
);


const loadSCPGW = (payUrl: string, paymentTitle: string, returnURL: string) => {
  ScApplePay.loadSCPGW({"payUrl": payUrl, "paymentTitle": paymentTitle, "returnURL": returnURL});
}


export * from './definitions';
export { ScApplePay, loadSCPGW }; //PaymentData
