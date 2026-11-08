"use client";

import { Component, type ReactNode } from "react";

type Props = { children: ReactNode };
type State = { message: string | null };

export class ErrorBoundary extends Component<Props, State> {
  state: State = { message: null };

  static getDerivedStateFromError(error: Error): State {
    return { message: error.message || "Error" };
  }

  render() {
    if (this.state.message) {
      return (
        <div className="m-4 rounded-2xl bg-white p-6 ring-1 ring-red-200 dark:bg-slate-900" role="alert">
          <h2 className="text-lg font-semibold">Bir sorun oluştu</h2>
          <p className="mt-2 text-sm text-slate-600">{this.state.message}</p>
          <button
            type="button"
            className="mt-4 rounded-lg bg-brand px-3 py-2 text-sm text-white"
            onClick={() => this.setState({ message: null })}
          >
            Yeniden dene
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
