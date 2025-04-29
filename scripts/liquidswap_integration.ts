import { AptosClient, AptosAccount, TxnBuilderTypes, BCS } from '@aptos-labs/ts-sdk';
import { LIQUIDSWAP_POOL_ADDRESS } from '../frontend/src/config/constants';

export class LiquidswapIntegration {
  private client: AptosClient;
  private account: AptosAccount;

  constructor(nodeUrl: string, privateKey: string) {
    this.client = new AptosClient(nodeUrl);
    this.account = AptosAccount.fromPrivateKey(Buffer.from(privateKey, 'hex'));
  }

  async createLiquidityPool(
    patentTokenAddress: string,
    aptAmount: number,
    tokenAmount: number
  ): Promise<string> {
    try {
      const payload = {
        type: "entry_function_payload",
        function: `${LIQUIDSWAP_POOL_ADDRESS}::router::add_liquidity`,
        type_arguments: [
          "0x1::aptos_coin::AptosCoin",
          `${patentTokenAddress}::patent_token::PatentToken`
        ],
        arguments: [
          aptAmount.toString(),
          tokenAmount.toString(),
          "0", // min_apt_amount
          "0", // min_token_amount
        ],
      };

      const txnHash = await this.client.generateSignSubmitTransaction(
        this.account,
        payload
      );

      await this.client.waitForTransaction(txnHash);
      return txnHash;
    } catch (error) {
      console.error('Error creating liquidity pool:', error);
      throw error;
    }
  }

  async swapAptForPatentToken(
    patentTokenAddress: string,
    aptAmount: number,
    minTokenAmount: number
  ): Promise<string> {
    try {
      const payload = {
        type: "entry_function_payload",
        function: `${LIQUIDSWAP_POOL_ADDRESS}::router::swap_exact_apt_for_token`,
        type_arguments: [
          `${patentTokenAddress}::patent_token::PatentToken`
        ],
        arguments: [
          aptAmount.toString(),
          minTokenAmount.toString(),
        ],
      };

      const txnHash = await this.client.generateSignSubmitTransaction(
        this.account,
        payload
      );

      await this.client.waitForTransaction(txnHash);
      return txnHash;
    } catch (error) {
      console.error('Error swapping APT for patent token:', error);
      throw error;
    }
  }

  async swapPatentTokenForApt(
    patentTokenAddress: string,
    tokenAmount: number,
    minAptAmount: number
  ): Promise<string> {
    try {
      const payload = {
        type: "entry_function_payload",
        function: `${LIQUIDSWAP_POOL_ADDRESS}::router::swap_exact_token_for_apt`,
        type_arguments: [
          `${patentTokenAddress}::patent_token::PatentToken`
        ],
        arguments: [
          tokenAmount.toString(),
          minAptAmount.toString(),
        ],
      };

      const txnHash = await this.client.generateSignSubmitTransaction(
        this.account,
        payload
      );

      await this.client.waitForTransaction(txnHash);
      return txnHash;
    } catch (error) {
      console.error('Error swapping patent token for APT:', error);
      throw error;
    }
  }

  async getPoolReserves(patentTokenAddress: string): Promise<{
    aptReserve: number;
    tokenReserve: number;
  }> {
    try {
      const resource = await this.client.getAccountResource(
        LIQUIDSWAP_POOL_ADDRESS,
        `${LIQUIDSWAP_POOL_ADDRESS}::pool::Pool<0x1::aptos_coin::AptosCoin,${patentTokenAddress}::patent_token::PatentToken>`
      );

      return {
        aptReserve: Number(resource.data.coin_x_reserve.value),
        tokenReserve: Number(resource.data.coin_y_reserve.value),
      };
    } catch (error) {
      console.error('Error getting pool reserves:', error);
      throw error;
    }
  }
} 