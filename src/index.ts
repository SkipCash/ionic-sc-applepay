import { registerPlugin } from '@capacitor/core';

import { ScApplePayPlugin, PaymentData } from './definitions'; //PaymentData


const ScApplePay = registerPlugin<ScApplePayPlugin>(
  'ScApplePay', {
    // web: () => import('./web').then(m => new m.ScApplePayWeb()),
  }
);


const initiatePayment = (paymentData: PaymentData) => {
  const paymentDataString = JSON.stringify(paymentData);
  ScApplePay.initiatePayment({"paymentData": paymentDataString});
}

const isWalletHasCards = async () => {
  const result = ScApplePay.isWalletHasCards()

  return result;
}

const setupNewCard = () => {
  ScApplePay.setupNewCard();
}

const loadSCPGW = (payUrl: string, paymentTitle: string, returnURL: string) => {
  ScApplePay.loadSCPGW({"payUrl": payUrl, "paymentTitle": paymentTitle, "returnURL": returnURL});
}


export * from './definitions';
export { 
  ScApplePay, initiatePayment, 
  isWalletHasCards, setupNewCard, 
  loadSCPGW, PaymentData
 };
