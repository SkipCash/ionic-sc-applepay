export interface ScApplePayPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
