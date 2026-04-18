/**
 * Duration (Value Object)
 * Devoxx format durations:
 *  - 15 minutes = Quickie
 *  - 30 minutes = Tools-in-Action
 *  - 45 minutes = Conference
 *  - 90 minutes = Deep Dive
 */
export type Duration = 15 | 30 | 45 | 90;

/**
 * InvalidDurationError (Domain Error)
 * Thrown when an invalid duration is provided.
 */
export class InvalidDurationError extends Error {
  constructor(value: number) {
    super(
      `Invalid duration: ${value}. Duration must be 15 (Quickie), 30 (Tools-in-Action), 45 (Conference), or 90 (Deep Dive) minutes.`,
    );
    this.name = 'InvalidDurationError';
  }
}

/**
 * InvalidTitleLengthError (Domain Error)
 * Thrown when a talk title exceeds the maximum allowed length of 100 characters.
 */
export class InvalidTitleLengthError extends Error {
  constructor(actualLength: number) {
    super(
      `Title length (${actualLength} characters) exceeds the maximum allowed length of 100 characters`,
    );
    this.name = 'InvalidTitleLengthError';
  }
}

/**
 * InvalidBioLengthError (Domain Error)
 * Thrown when a speaker bio is outside the allowed range of 50-500 characters.
 */
export class InvalidBioLengthError extends Error {
  constructor(actualLength: number, constraint: { min: number; max: number }) {
    const message =
      actualLength < constraint.min
        ? `Bio length (${actualLength} characters) is below the minimum of ${constraint.min} characters`
        : `Bio length (${actualLength} characters) exceeds the maximum of ${constraint.max} characters`;
    super(message);
    this.name = 'InvalidBioLengthError';
  }
}

/**
 * Talk (Domain Entity)
 * Represents a conference session submitted to Devoxx.
 *
 * Invariants:
 *  - id, title, speakerName must be non-empty strings
 *  - bio must be between 50 and 500 characters (after trimming)
 *  - duration must be exactly 15, 30, 45, or 90 minutes
 *
 * Immutability: All mutation methods return a NEW instance.
 * No external imports: Pure domain logic.
 */
export class Talk {
  constructor(
    public readonly id: string,
    public readonly title: string,
    public readonly abstract: string,
    public readonly speakerName: string,
    public readonly bio: string,
    private readonly _duration: Duration,
  ) {
    if (!id || id.trim() === '') {
      throw new Error('Talk id must be provided');
    }
    if (!title || title.trim() === '') {
      throw new Error('Talk title must be provided');
    }
    if (title.length > 100) {
      throw new InvalidTitleLengthError(title.length);
    }
    if (!speakerName || speakerName.trim() === '') {
      throw new Error('Talk speakerName must be provided');
    }
    const trimmedBio = bio.trim();
    if (trimmedBio.length < 50 || trimmedBio.length > 500) {
      throw new InvalidBioLengthError(trimmedBio.length, { min: 50, max: 500 });
    }
    if (!this.isValidDuration(_duration)) {
      throw new InvalidDurationError(_duration);
    }
  }

  /** Read-only access to duration */
  get duration(): Duration {
    return this._duration;
  }

  /**
   * Returns the Devoxx format name for the current duration.
   */
  get format(): 'Quickie' | 'Tools-in-Action' | 'Conference' | 'Deep Dive' {
    switch (this._duration) {
      case 15:
        return 'Quickie';
      case 30:
        return 'Tools-in-Action';
      case 45:
        return 'Conference';
      case 90:
        return 'Deep Dive';
    }
  }

  /**
   * changeDuration
   * Changes the talk duration. Validates that the new duration
   * matches Devoxx formats: 15, 30, 45, or 90 minutes.
   *
   * @throws InvalidDurationError if duration is invalid
   * @returns A NEW Talk instance with updated duration
   */
  changeDuration(newDuration: number): Talk {
    if (!this.isValidDuration(newDuration)) {
      throw new InvalidDurationError(newDuration);
    }
    return new Talk(
      this.id,
      this.title,
      this.abstract,
      this.speakerName,
      this.bio,
      newDuration as Duration,
    );
  }

  /**
   * Type guard for valid durations
   */
  private isValidDuration(value: number): value is Duration {
    return value === 15 || value === 30 || value === 45 || value === 90;
  }
}
