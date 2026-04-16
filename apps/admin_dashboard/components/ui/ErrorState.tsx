interface ErrorStateProps {
  message: string;
}

export function ErrorState({ message }: ErrorStateProps) {
  return (
    <div className="rounded-xl border border-error/20 bg-error-container p-6 text-sm text-on-error-container">
      {message}
    </div>
  );
}
