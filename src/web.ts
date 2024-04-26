import { WebPlugin } from '@capacitor/core';

import type { ScApplePayPlugin } from './definitions';

export class ScApplePayWeb extends WebPlugin implements ScApplePayPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
