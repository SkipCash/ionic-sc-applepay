import { WebPlugin } from '@capacitor/core';

import type { ScApplePayPlugin } from './definitions';

export class ScApplePayWeb extends WebPlugin implements ScApplePayPlugin {
  loadSCPGW(options: { payUrl: string, paymentTitle: string, returnURL: string }): void {

  }
}
