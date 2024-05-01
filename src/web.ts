import { WebPlugin } from '@capacitor/core';

import type { ScApplePayPlugin } from './definitions';

export class ScApplePayWeb extends WebPlugin implements ScApplePayPlugin {
  loadSCPGW(options: { payUrl: string, paymentTitle: string, returnURL: string }): void {
    console.log(options.payUrl);
    console.log(options.paymentTitle);
    console.log(options.returnURL);
  }
}
