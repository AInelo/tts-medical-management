// utils/wrapController.ts
import { Request, Response, NextFunction } from 'express';

export const wrapController = (
  fn: (req: Request, res: Response) => Promise<Response>
) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      await fn(req, res);
    } catch (error) {
      next(error);
    }
  };
};
